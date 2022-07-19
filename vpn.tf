# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }

}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    } 
  }
}

# Deploy Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "RG-VPN"
  location = "UK South"
 }


####################################################
#               H  U  B
####################################################

# Deploy VNET
resource "azurerm_virtual_network" "vnet01" {
  name                = "vnet-hub"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["192.168.0.0/16"]
}

# Deploy Subnet
resource "azurerm_subnet" "sub01" {
  name                 = "sub-hub01"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet01.name
  address_prefixes     = ["192.168.1.0/24"]
}

# Deploy NSG
resource "azurerm_network_security_group" "nsg01" {
  name                = "nsg-hub01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "192.168.1.0/24"
  }
}

# Associar NSG Subnet
resource "azurerm_subnet_network_security_group_association" "nsg01" {
  subnet_id                 = azurerm_subnet.sub01.id
  network_security_group_id = azurerm_network_security_group.nsg01.id
}


# Deploy Public IP
resource "azurerm_public_ip" "pip01" {
  name                = "pip-vmlnx01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
}

# Deploy NIC
resource "azurerm_network_interface" "vnic01" {
  name                = "nic-vm-lnx01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sub01.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip01.id
  }
}

# Deploy VM
resource "azurerm_linux_virtual_machine" "vm01" {
  name                            = "vm-lnx01"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_D2s_V3"
  admin_username                  = "azadmin"
  admin_password                  = "Partiunuvem@123"
  disable_password_authentication = "false"
  network_interface_ids = [
    azurerm_network_interface.vnic01.id,
  ]


source_image_reference {
  publisher = "Canonical"
  offer     = "UbuntuServer"
  sku       = "18.04-LTS"
  version   = "latest"
}

os_disk {
  storage_account_type = "Standard_LRS"
  caching              = "ReadWrite"
 }
}


####################################################
#                S P O K E 1 - Brazil
####################################################

# Deploy VNET
resource "azurerm_virtual_network" "vnet-bra" {
  name                = "vnet-spoke01"
  location            = "Brazil South"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["172.16.0.0/16"]
}


# Deploy Subnet
resource "azurerm_subnet" "sub-bra" {
  name                 = "sub-spoke01"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet-bra.name
  address_prefixes     = ["172.16.1.0/24"]
}

# Deploy NSG
resource "azurerm_network_security_group" "nsg-bra" {
  name                = "nsg-spoke01"
  location            = "Brazil South"
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "172.16.1.0/24"
  }
}

# Associar NSG Subnet
resource "azurerm_subnet_network_security_group_association" "nsg-bra" {
  subnet_id                 = azurerm_subnet.sub-bra.id
  network_security_group_id = azurerm_network_security_group.nsg-bra.id
}


# Deploy Public IP
resource "azurerm_public_ip" "pip02" {
  name                = "pip-vmlnx02"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "Brazil South"
  allocation_method   = "Dynamic"
}

# Deploy NIC
resource "azurerm_network_interface" "vnic02" {
  name                = "nic-vm-lnx02"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "Brazil South"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sub-bra.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip02.id
  }
}


# Deploy VM
resource "azurerm_linux_virtual_machine" "vm02" {
  name                            = "vm-lnx02"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = "Brazil South"
  size                            = "Standard_D2s_V3"
  admin_username                  = "azadmin"
  admin_password                  = "Partiunuvem@123"
  disable_password_authentication = "false"
  network_interface_ids = [
    azurerm_network_interface.vnic02.id,
  ]

   source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}

####################################################
#                S P O K E 2 - UK West
####################################################

# Deploy VNET
resource "azurerm_virtual_network" "vnet03" {
  name                = "vnet-spoke02"
  location            = "UK west"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]
}


# Deploy Subnet
resource "azurerm_subnet" "sub03" {
  name                 = "sub-spoke02"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet03.name
  address_prefixes     = ["10.1.0.0/24"]
}

# Deploy NSG
resource "azurerm_network_security_group" "nsg03" {
  name                = "nsg-spoke02"
  location            = "UK west"
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "172.16.1.0/24"
  }
}

# Associar NSG Subnet
resource "azurerm_subnet_network_security_group_association" "nsg03" {
  subnet_id                 = azurerm_subnet.sub03.id
    network_security_group_id = azurerm_network_security_group.nsg03.id
}


# Deploy Public IP
resource "azurerm_public_ip" "pip03" {
  name                = "pip-vmlnx03"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "UK west"
  allocation_method   = "Dynamic"
}

# Deploy NIC
resource "azurerm_network_interface" "vnic03" {
  name                = "nic-vm-lnx03"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "UK west"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sub03.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip03.id
  }
}

# Deploy VM
resource "azurerm_linux_virtual_machine" "vm03" {
  name                            = "vm-lnx03"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = "UK west"
  size                            = "Standard_D2s_V3"
  admin_username                  = "azadmin"
  admin_password                  = "Partiunuvem@123"
  disable_password_authentication = "false"
  network_interface_ids = [
    azurerm_network_interface.vnic03.id,
  ]

   source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}


#######################################################################
#                O N  P R E M I S S E S  - North Europe
#######################################################################

# Deploy VNET
resource "azurerm_virtual_network" "vnet04" {
  name                = "vnet-OnPremisses"
  location            = "North Europe"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.2.0.0/16"]
}

# Deploy Subnet
resource "azurerm_subnet" "sub04" {
  name                 = "sub-NorthEUR"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet04.name
  address_prefixes     = ["10.2.0.0/24"]
}

# Deploy NSG
resource "azurerm_network_security_group" "nsg04" {
  name                = "nsg-NorthEUR"
  location            = "North Europe"
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "10.2.0.0/24"
  }
}

# Associar NSG Subnet
resource "azurerm_subnet_network_security_group_association" "nsg04" {
  subnet_id                 = azurerm_subnet.sub04.id
  network_security_group_id = azurerm_network_security_group.nsg04.id
}

# Deploy Public IP
resource "azurerm_public_ip" "pip04" {
  name                = "pip-vmwin01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "North Europe"
  allocation_method   = "Dynamic"
}

# Deploy NIC
resource "azurerm_network_interface" "vnic04" {
  name                = "nic-vm-win01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "North Europe"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sub04.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip04.id
  }
}

# Deploy VM
resource "azurerm_windows_virtual_machine" "vm04" {
  name                            = "vm-win01"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = "North Europe"
  size                            = "Standard_D2as_V4"
  admin_username                  = "azadmin"
  admin_password                  = "Partiunuvem@123"
  network_interface_ids = [
    azurerm_network_interface.vnic04.id,
  ]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}

############################################################
#       V I R T U A L  N E T W O R K  G A T E W A Y
############################################################

resource "azurerm_subnet" "sub05" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet01.name
  address_prefixes     = ["192.168.2.0/27"]
}

resource "azurerm_public_ip" "pip05" {
  name                = "pip-vng"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "vng01" {
  name                = "vng-hub"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.pip05.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.sub05.id
  }
}
