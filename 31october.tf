terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.110"
    }
  }

  cloud {
    organization = "YOUR_TERRAFORM_ORG_NAME" # Replace with your Terraform Cloud org
    workspaces {
      name = "azure-vm-demo"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg_new" {
  name     = "rg-webapp-demo"
  location = "Canada Central"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "my-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg_new.location
  resource_group_name = azurerm_resource_group.rg_new.name
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "my-subnet"
  resource_group_name  = azurerm_resource_group.rg_new.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "pip" {
  name                = "my-public-ip"
  location            = azurerm_resource_group.rg_new.location
  resource_group_name = azurerm_resource_group.rg_new.name
  allocation_method   = "Dynamic"
}

# Network Interface
resource "azurerm_network_interface" "ama" {
  name                = "my-ama"
  location            = azurerm_resource_group.rg_new.location
  resource_group_name = azurerm_resource_group.rg_new.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "my-nsg"
  location            = azurerm_resource_group.rg_new.location
  resource_group_name = azurerm_resource_group.rg_new.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "22"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }
}

# Associate NIC with NSG
resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.ama.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "myvm01"
  resource_group_name = azurerm_resource_group.rg_new.name
  location            = azurerm_resource_group.rg_new.location
  size                = "Standard_B2s"
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [azurerm_network_interface.ama.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
