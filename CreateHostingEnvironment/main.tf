####

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg_varName" {
  name     = "${var.prefix}-resources"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "VNet_varName" {
  name                = "${var.prefix}-network"
  resource_group_name = "${azurerm_resource_group.rg_varName.name}"
  location            = "${azurerm_resource_group.rg_varName.location}"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  virtual_network_name = "${azurerm_virtual_network.VNet_varName.name}"
  resource_group_name  = "${azurerm_resource_group.rg_varName.name}"
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "backend"
  virtual_network_name = "${azurerm_virtual_network.VNet_varName.name}"
  resource_group_name  = "${azurerm_resource_group.rg_varName.name}"
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "database" {
  name                 = "database"
  virtual_network_name = "${azurerm_virtual_network.VNet_varName.name}"
  resource_group_name  = "${azurerm_resource_group.rg_varName.name}"
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_network_security_group" "NSG_BackEnd" {
  name                = "${var.prefix}-nsg"
  resource_group_name = "${azurerm_resource_group.rg_varName.name}"
  location            = "${azurerm_resource_group.rg_varName.location}"
}

# NOTE: this allows SSH from any network
resource "azurerm_network_security_rule" "ssh" {
  name                        = "ssh"
  resource_group_name         = "${azurerm_resource_group.rg_varName.name}"
  network_security_group_name = "${azurerm_network_security_group.NSG_BackEnd.name}"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}


# Linux VM
resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  resource_group_name = azurerm_resource_group.rg_varName.name
  location            = azurerm_resource_group.rg_varName.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.frontend.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = "${var.prefix}-vm"
  resource_group_name             = azurerm_resource_group.rg_varName.name
  location                        = azurerm_resource_group.rg_varName.location
  size                            = "Standard_F2"
  admin_username                  = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  admin_ssh_key {
    username = "adminuser"
    public_key = file("~/.ssh/mykey1.key.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}
## End Linux VM


# Windows VM
resource "azurerm_network_interface" "winmain" {
  name                = "${var.prefix}-nic"
  resource_group_name = azurerm_resource_group.rg_varName.name
  location            = azurerm_resource_group.rg_varName.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.frontend.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "winmain" {
  name                            = "${var.prefix}-vm"
  resource_group_name             = azurerm_resource_group.rg_varName.name
  location                        = azurerm_resource_group.rg_varName.location
  size                            = "Standard_F2"
  admin_username                  = "adminuser"
  admin_password                  = "P@ssw0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.winmain.id,
  ]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}
## End Windows VM