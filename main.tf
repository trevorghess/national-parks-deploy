terraform {
  required_version = "> 0.11.0"
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = "${var.azure_sub_id}"
  tenant_id       = "${var.azure_tenant_id}"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "rg" {
  name     = "${var.application}-th-rg"
  location = "${var.azure_region}"

  tags {
    X-Contact     = "The Example Maintainer <maintainer@example.com>"
    X-Application = "national-parks"
    X-ManagedBy   = "Terraform"
  }
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.application}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  tags {
    X-Contact     = "The Example Maintainer <maintainer@example.com>"
    X-Application = "national-parks"
    X-ManagedBy   = "Terraform"
  }
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.application}-subnet"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.0.10.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "pip" {
  name                         = "${var.application}-pip-${count.index}"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "static"
  count                        = 2

  tags {
    X-Contact     = "The Example Maintainer <maintainer@example.com>"
    X-Application = "national-parks"
    X-ManagedBy   = "Terraform"
  }
}

resource "azurerm_public_ip" "vmsspip" {
  name                         = "${var.application}-vmsspip"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "static"

  tags {
    X-Contact     = "The Example Maintainer <maintainer@example.com>"
    X-Application = "national-parks"
    X-ManagedBy   = "Terraform"
  }
}

resource "azurerm_lb" "vmss" {
  name                = "vmss-lb"
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.vmsspip.id}"
  }

  tags = {
    X-Contact     = "The Example Maintainer <maintainer@example.com>"
    X-Application = "national-parks"
    X-ManagedBy   = "Terraform"
  }
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.vmss.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "vmss" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.vmss.id}"
  name                = "ssh-running-probe"
  port                = "${var.application_port}"
}

resource "azurerm_lb_rule" "lbnatrule" {
  resource_group_name            = "${azurerm_resource_group.rg.name}"
  loadbalancer_id                = "${azurerm_lb.vmss.id}"
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = "${var.lb_application_port}"
  backend_port                   = "${var.application_port}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.bpepool.id}"
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = "${azurerm_lb_probe.vmss.id}"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "sg" {
  name                = "${var.application}-sg"
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

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

  security_rule {
    name                       = "8080"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "9631"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "9631"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "9638"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "9638"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "27017"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "27017"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "28017"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "28017"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    X-Contact     = "The Example Maintainer <maintainer@example.com>"
    X-Application = "national-parks"
    X-ManagedBy   = "Terraform"
  }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
  name                      = "${var.application}-nic${count.index}"
  location                  = "${var.azure_region}"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.sg.id}"
  count                     = 2

  ip_configuration {
    name                          = "ipconfig${count.index}"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.pip.*.id, count.index)}"
  }

  tags {
    X-Contact     = "The Example Maintainer <maintainer@example.com>"
    X-Application = "national-parks"
    X-ManagedBy   = "Terraform"
  }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.rg.name}"
  }

  byte_length = 8
}

//////STORAGE///////
////////////////////

# Create initial peer
resource "azurerm_storage_account" "stor" {
  name                     = "stor${random_id.randomId.hex}"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${var.azure_region}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags {
    X-Contact     = "The Example Maintainer <maintainer@example.com>"
    X-Application = "national-parks"
    X-ManagedBy   = "Terraform"
  }
}

resource "azurerm_storage_container" "storcont" {
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  storage_account_name  = "${azurerm_storage_account.stor.name}"
  container_access_type = "private"
}

//////INSTANCES///////
//////////////////////
resource "azurerm_virtual_machine" "initial-peer" {
  name                          = "${var.application}-initialpeer"
  location                      = "${var.azure_region}"
  resource_group_name           = "${azurerm_resource_group.rg.name}"
  network_interface_ids         = ["${azurerm_network_interface.nic.0.id}"]
  vm_size                       = "Standard_DS1_v2"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "${var.application}-initialpeer-osdisk"
    vhd_uri       = "${azurerm_storage_account.stor.primary_blob_endpoint}${azurerm_storage_container.storcont.name}/${var.application}-initialpeer-osdisk.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "${var.application}-initialpeer"
    admin_username = "${var.azure_image_user}"
    admin_password = "${var.azure_image_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false

    ssh_keys {
      path     = "/home/${var.azure_image_user}/.ssh/authorized_keys"
      key_data = "${file("${var.azure_public_key_path}")}"
    }
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.stor.primary_blob_endpoint}"
  }

  provisioner "habitat" {
    permanent_peer = true
    use_sudo       = true
    service_type   = "systemd"

    connection {
      host     = "${azurerm_public_ip.pip.0.ip_address}"
      user     = "${var.azure_image_user}"
      password = "${var.azure_image_password}"
    }
  }

  tags {
    X-Contact     = "The Example Maintainer <maintainer@example.com>"
    X-Application = "national-parks"
    X-ManagedBy   = "Terraform"
  }
}

# Create mongodb instance
resource "azurerm_virtual_machine" "mongodb" {
  depends_on                    = ["azurerm_virtual_machine.initial-peer"]
  name                          = "${var.application}-mongodb"
  location                      = "${var.azure_region}"
  resource_group_name           = "${azurerm_resource_group.rg.name}"
  network_interface_ids         = ["${azurerm_network_interface.nic.1.id}"]
  vm_size                       = "Standard_DS1_v2"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "${var.application}-mongodb-osdisk"
    vhd_uri       = "${azurerm_storage_account.stor.primary_blob_endpoint}${azurerm_storage_container.storcont.name}/${var.application}-mongodb-osdisk.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "${var.application}-mongodb"
    admin_username = "${var.azure_image_user}"
    admin_password = "${var.azure_image_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false

    ssh_keys {
      path     = "/home/${var.azure_image_user}/.ssh/authorized_keys"
      key_data = "${file("${var.azure_public_key_path}")}"
    }
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.stor.primary_blob_endpoint}"
  }

  provisioner "habitat" {
    peer         = "${azurerm_network_interface.nic.0.private_ip_address}"
    use_sudo     = true
    service_type = "systemd"

    service {
      name     = "${var.habitat_origin}/np-mongodb"
      topology = "standalone"
      group    = "${var.group}"
      channel  = "${var.release_channel}"
      strategy = "${var.update_strategy}"
    }

    connection {
      host     = "${azurerm_public_ip.pip.1.ip_address}"
      user     = "${var.azure_image_user}"
      password = "${var.azure_image_password}"
    }
  }

  tags {
    X-Contact     = "The Example Maintainer <maintainer@example.com>"
    X-Application = "national-parks"
    X-ManagedBy   = "Terraform"
  }
}

# Create web application instance scale set 
resource "azurerm_virtual_machine_scale_set" "vmss" {
  depends_on          = ["azurerm_virtual_machine.mongodb"]
  name                = "vmscaleset"
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  upgrade_policy_mode = "Manual"

  sku {
    name     = "Standard_DS1_v2"
    tier     = "Standard"
    capacity = "${var.vmss_capacity}"
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix = "vmlab"
    admin_username       = "${var.azure_image_user}"
    admin_password       = "${var.azure_image_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  network_profile {
    name                      = "terraformnetworkprofile"
    primary                   = true
    network_security_group_id = "${azurerm_network_security_group.sg.id}"

    ip_configuration {
      name                                   = "IPConfiguration"
      subnet_id                              = "${azurerm_subnet.subnet.id}"
      load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.bpepool.id}"]
    }
  }

  extension {
    name                 = "chef-extension"
    publisher            = "Chef.Bootstrap.WindowsAzure"
    type                 = "LinuxChefClient"
    type_handler_version = "1210.12"

    settings = <<SETTINGS
    {
      "bootstrap_options": {
        "chef_server_url": "${var.automate_server}/organizations/hessco",
        "validation_client_name": "hessco-validator"
      },
      "runlist": "recipe[national-parks::default]",
      "client_rb": "ssl_verify_mode :verify_none\n",  
      "custom_json_attr": {
        "habitat_peer": "${azurerm_network_interface.nic.0.private_ip_address}"
      },
      "validation_key_format": "plaintext",
      "chef_daemon_interval": "5",
      "daemon" : "service"
    }
  SETTINGS

    protected_settings = <<PROTECTEDSETTINGS
    {
      "validation_key": "${var.validation_key}"
    }
  PROTECTEDSETTINGS
  }

  # provisioner "habitat" {
  #   peer         = "${azurerm_public_ip.pip.0.ip_address}"
  #   use_sudo     = true
  #   service_type = "systemd"


  #   service {
  #     binds    = ["database:np-mongodb.${var.group}"]
  #     name     = "${var.habitat_origin}/national-parks"
  #     topology = "standalone"
  #     group    = "${var.group}"
  #     channel  = "${var.release_channel}"
  #     strategy = "${var.update_strategy}"
  #   }


  #   connection {
  #     user     = "${var.azure_image_user}"
  #     password = "${var.azure_image_password}"
  #   }
  # }

  tags = {
    X-Contact     = "The Example Maintainer <maintainer@example.com>"
    X-Application = "national-parks"
    X-ManagedBy   = "Terraform"
  }
}
