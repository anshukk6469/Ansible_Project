provider "azurerm" {
    features {}
  client_id       = "3d1a9664-1652-46c8-815f-e3a2fc791d3d"
  client_secret   = "fq78Q~TN2oMsQucZCgwqpIh-BV8KXL~~bCxRgbBm"
  tenant_id       = "1489158f-cf8f-452f-8ef6-e75f32eb2947"
  subscription_id = "03e309ec-893b-400c-a4f5-d9ca458b5e2f"
}

resource "azurerm_resource_group" "example" {
  name     = "deep-linux"
  location = "West Europe"
}

resource "azurerm_public_ip" "new" {
  name                = "Deep-ip${count.index}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"
  count = 2
  tags = {
    environment = "Production"
  }
  provisioner "local-exec" {
    command = "echo ${self.ip_address} >> hosts"
  }
}
resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "example" {
  name                = "example-nic${count.index}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  count = 2
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.new[count.index].id
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "linux-machine${count.index}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  admin_password = "Pa$$w0rd@6469"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.example[count.index].id,
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  count = 2

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "93-gen2"
    version   = "latest"
  }
}

resource "azurerm_network_security_group" "example" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
    security_rule {
    name                       = "test124"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

output "ip" {
  value = azurerm_public_ip.new[*].ip_address
}

