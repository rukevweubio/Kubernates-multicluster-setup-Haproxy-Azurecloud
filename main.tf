# Fetch existing Resource Group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "k8s-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
}

# Create Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "k8s-subnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Groups
resource "azurerm_network_security_group" "masters_nsg" {
  name                = "masters-nsg"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "allow-all"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "workers_nsg" {
  name                = "workers-nsg"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "allow-all"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "haproxy_nsg" {
  name                = "haproxy-nsg"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "allow-all"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Public IPs
resource "azurerm_public_ip" "masters_pip" {
  count               = var.master_count
  name                = "master-${count.index}-pip"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "workers_pip" {
  count               = var.worker_count
  name                = "worker-${count.index}-pip"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "haproxy_pip" {
  name                = "haproxy-pip"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
}

# NICs
resource "azurerm_network_interface" "master_nic" {
  count               = var.master_count
  name                = "master-${count.index}-nic"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "master-${count.index}-ipcfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.masters_pip[count.index].id
  }
}

resource "azurerm_network_interface" "worker_nic" {
  count               = var.worker_count
  name                = "worker-${count.index}-nic"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "worker-${count.index}-ipcfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.workers_pip[count.index].id
  }
}

resource "azurerm_network_interface" "haproxy_nic" {
  name                = "haproxy-nic"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "haproxy-ipcfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.haproxy_pip.id
  }
}

# NSG Associations
resource "azurerm_network_interface_security_group_association" "master_assoc" {
  count                     = var.master_count
  network_interface_id      = azurerm_network_interface.master_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.masters_nsg.id
}

resource "azurerm_network_interface_security_group_association" "worker_assoc" {
  count                     = var.worker_count
  network_interface_id      = azurerm_network_interface.worker_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.workers_nsg.id
}

resource "azurerm_network_interface_security_group_association" "haproxy_assoc" {
  network_interface_id      = azurerm_network_interface.haproxy_nic.id
  network_security_group_id = azurerm_network_security_group.haproxy_nsg.id
}

# Master VMs
resource "azurerm_linux_virtual_machine" "master" {
  count                         = var.master_count
  name                          = "master-${count.index}"
  resource_group_name           = data.azurerm_resource_group.main.name
  location                      = data.azurerm_resource_group.main.location
  size                          = var.vm_size
  admin_username                = var.admin_username
  admin_password                = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.master_nic[count.index].id]

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

# Worker VMs
resource "azurerm_linux_virtual_machine" "worker" {
  count                         = var.worker_count
  name                          = "worker-${count.index}"
  resource_group_name           = data.azurerm_resource_group.main.name
  location                      = data.azurerm_resource_group.main.location
  size                          = var.vm_size
  admin_username                = var.admin_username
  admin_password                = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.worker_nic[count.index].id]

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

# HAProxy VM
resource "azurerm_linux_virtual_machine" "haproxy" {
  name                          = "haproxy"
  resource_group_name           = data.azurerm_resource_group.main.name
  location                      = data.azurerm_resource_group.main.location
  size                          = var.vm_size
  admin_username                = var.admin_username
  admin_password                = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.haproxy_nic.id]

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
