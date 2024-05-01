# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.90.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}

#Create RG
resource "azurerm_resource_group" "test_rg_we" {
  name     = "example-rg-we"
  location = "West Europe"
}

#Create virtual network
resource "azurerm_virtual_network" "test_vn_we" {
  name = "vn-we"
  location = azurerm_resource_group.test_rg_we.location
  resource_group_name = azurerm_resource_group.test_rg_we.name
  address_space = ["10.0.0.0/16"]
}

#Create subnet_1
resource "azurerm_subnet" "test_sn_we_1" {
  name = "sn-we_1"
  resource_group_name = azurerm_resource_group.test_rg_we.name
  virtual_network_name = azurerm_virtual_network.test_vn_we.name
  address_prefixes = ["10.0.1.0/24"]
}

#Create subnet_bastion
resource "azurerm_subnet" "AzureBastionSubnet" {
  name = "AzureBastionSubnet"
  resource_group_name = azurerm_resource_group.test_rg_we.name
  virtual_network_name = azurerm_virtual_network.test_vn_we.name
  address_prefixes = ["10.0.2.0/27"]
}

#Create internal NIC
resource "azurerm_network_interface" "internal" {
  name = "nic-we-int"
  location = azurerm_resource_group.test_rg_we.location
  resource_group_name = azurerm_resource_group.test_rg_we.name

  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.test_sn_we_1.id
    private_ip_address_allocation = "Dynamic"
  }
}

#Create VM
resource "azurerm_windows_virtual_machine" "test_vm_we_1" {
  name = "test-vm-we-1"
  resource_group_name = azurerm_resource_group.test_rg_we.name
  location = azurerm_resource_group.test_rg_we.location
  size = "Standard_B1s"
  admin_username = "Qwerty123"
  admin_password = "Qwerty123"

  network_interface_ids = [
    azurerm_network_interface.internal.id
  ]

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer = "WindowsServer"
    sku = "2016-Datacenter"
    version = "latest"
  }
}

resource "azurerm_bastion_host" "bastion" {
  name                = "vm-bastion"
  location            = azurerm_resource_group.test_rg_we.location
  resource_group_name = azurerm_resource_group.test_rg_we.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.AzureBastionSubnet.id
    public_ip_address_id = azurerm_public_ip.bastion_public_ip.id
  }
}

resource "azurerm_public_ip" "bastion_public_ip" {
  name                = "vm-bastion-pip"
  location            = azurerm_resource_group.test_rg_we.location
  resource_group_name = azurerm_resource_group.test_rg_we.name
  allocation_method   = "Static"
  sku                 = "Standard"
}