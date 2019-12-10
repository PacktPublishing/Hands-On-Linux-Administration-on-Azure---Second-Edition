provider "azurerm" {
    version = "~>1.33"
}

resource "azurerm_resource_group" "rg" {
    name     = "TFonAzure"
    location = "eastus"
}

resource "azurerm_virtual_network" "vnet" {
    name                = "tf-vnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.rg.name

}

resource "azurerm_subnet" "subnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "pip" {
    name                         = "tf-pip"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.rg.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_network_security_group" "nsg" {
    name                = "tf-nsg"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.rg.name
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_network_interface" "nic" {
    name                        = "tf-nic"
    location                    = "eastus"
    resource_group_name         = azurerm_resource_group.rg.name
    network_security_group_id   = azurerm_network_security_group.nsg.id

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.subnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.pip.id}"
    }

}

resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "tf-VM"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.nic.id]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "tfOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "tfvm"
        admin_username = "adminuser"
        admin_password = "Pa55w0rD!@1234"
    }
    
    os_profile_linux_config {
    disable_password_authentication = false
  }

}
