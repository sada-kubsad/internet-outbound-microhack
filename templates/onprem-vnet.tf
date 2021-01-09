#########################################################
# onprem VNet
#########################################################
resource "azurerm_virtual_network" "onprem-vnet" {
  name                = "onprem-vnet"
  location            = azurerm_resource_group.internet-outbound-microhack-rg.location
  resource_group_name = azurerm_resource_group.internet-outbound-microhack-rg.name
  address_space       = ["10.57.0.0/16"]
  
  tags = {
    environment = "onprem"
    deployment  = "terraform"
    microhack   = "internet-outbound"
  }
}

resource "azurerm_subnet" "onprem-workstation-subnet" {
    name                    = "workstation-subnet"
    resource_group_name     = azurerm_resource_group.internet-outbound-microhack-rg.name
    virtual_network_name    = azurerm_virtual_network.onprem-vnet.name
    address_prefix          = "10.57.1.0/24"
}

resource "azurerm_subnet" "onprem-proxy-subnet" {
    name                        = "proxy-subnet"
    resource_group_name         = azurerm_resource_group.internet-outbound-microhack-rg.name
    virtual_network_name        = azurerm_virtual_network.onprem-vnet.name
    address_prefix              = "10.57.2.0/24"
}

resource "azurerm_subnet" "onprem-bastion-subnet" {
    name                    = "AzureBastionSubnet"
    resource_group_name     = azurerm_resource_group.internet-outbound-microhack-rg.name
    virtual_network_name    = azurerm_virtual_network.onprem-vnet.name
    address_prefix          = "10.57.0.0/27"
}

resource "azurerm_network_security_group" "on-prem-proxy-subnet-nsg" {
  name                = "on-prem-proxy-subnet-nsg"
  location            = azurerm_resource_group.internet-outbound-microhack-rg.location
  resource_group_name = azurerm_resource_group.internet-outbound-microhack-rg.name

  security_rule {
    name                       = "allow-ISAKMP-from-any"
    priority                   = 220
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_ranges    = [500,4500]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = {
    environment = "onprem"
    deployment  = "terraform"
    microhack   = "internet-outbound"
  }
}

resource "azurerm_subnet_network_security_group_association" "onprem-proxy-subnet-nsg-association" {
  subnet_id                 = azurerm_subnet.onprem-proxy-subnet.id
  network_security_group_id = azurerm_network_security_group.on-prem-proxy-subnet-nsg.id
} 

#########################################################
# Azure hub VNet
#########################################################
resource "azurerm_virtual_network" "hub-vnet" {
  name                = "hub-vnet"
  location            = azurerm_resource_group.internet-outbound-microhack-rg.location
  resource_group_name = azurerm_resource_group.internet-outbound-microhack-rg.name
  address_space       = ["10.58.0.0/16"]

  tags = {
    environment = "cloud"
    deployment  = "terraform"
    microhack   = "internet-outbound"
  }
}

resource "azurerm_subnet" "hub-firewall-subnet" {
    name                    = "AzureFirewallSubnet"
    resource_group_name     = azurerm_resource_group.internet-outbound-microhack-rg.name
    virtual_network_name    = azurerm_virtual_network.hub-vnet.name
    address_prefix          = "10.58.1.0/24"
}

resource "azurerm_subnet" "hub-gateway-subnet" {
    name                    = "GatewaySubnet"
    resource_group_name     = azurerm_resource_group.internet-outbound-microhack-rg.name
    virtual_network_name    = azurerm_virtual_network.hub-vnet.name
    address_prefix          = "10.58.0.0/27"
}

  
#########################################################
# Azure wvd-spoke VNet
#########################################################
resource "azurerm_virtual_network" "wvd-spoke-vnet" {
  name                = "wvd-spoke-vnet"
  location            = azurerm_resource_group.internet-outbound-microhack-rg.location
  resource_group_name = azurerm_resource_group.internet-outbound-microhack-rg.name
  address_space       = ["10.59.0.0/16"]

  tags = {
    environment = "cloud"
    deployment  = "terraform"
    microhack   = "internet-outbound"
  }
}

resource "azurerm_subnet" "wvd-subnet" {
    name                    = "wvd-subnet"
    resource_group_name     = azurerm_resource_group.internet-outbound-microhack-rg.name
    virtual_network_name    = azurerm_virtual_network.wvd-spoke-vnet.name
    address_prefix          = "10.59.1.0/24"
}

resource "azurerm_subnet" "wvd-spoke-bastion-subnet" {
    name                    = "AzureBastionSubnet"
    resource_group_name     = azurerm_resource_group.internet-outbound-microhack-rg.name
    virtual_network_name    = azurerm_virtual_network.wvd-spoke-vnet.name
    address_prefix          = "10.59.0.0/27"
}

resource "azurerm_network_security_group" "wvd-subnet-nsg" {
  name                = "wvd-subnet-nsg"
  location            = azurerm_resource_group.internet-outbound-microhack-rg.location
  resource_group_name = azurerm_resource_group.internet-outbound-microhack-rg.name

  tags = {
    environment = "cloud"
    deployment  = "terraform"
    microhack   = "internet-outbound"
  }
}

resource "azurerm_subnet_network_security_group_association" "wvd-subnet-nsg-association" {
  subnet_id                 = azurerm_subnet.wvd-subnet.id
  network_security_group_id = azurerm_network_security_group.wvd-subnet-nsg.id
}

#########################################################
# Peering hub <--> wvd-spoke
#########################################################  
resource "azurerm_virtual_network_peering" "wvd-spoke-2-hub" {
  name                              = "wvd-spoke-2-hub"
  resource_group_name               = azurerm_resource_group.internet-outbound-microhack-rg.name
  virtual_network_name              = azurerm_virtual_network.wvd-spoke-vnet.name
  remote_virtual_network_id         = azurerm_virtual_network.hub-vnet.id
  allow_virtual_network_access      = true
  allow_forwarded_traffic           = true
  allow_gateway_transit             = false
  use_remote_gateways               = true
  
  depends_on                        = [azurerm_virtual_network_gateway.hub-vpngw]
}

resource "azurerm_virtual_network_peering" "hub-2-wvd-spoke" {
  name                              = "hub-2-wvd-spoke"
  resource_group_name               = azurerm_resource_group.internet-outbound-microhack-rg.name
  virtual_network_name              = azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_id         = azurerm_virtual_network.wvd-spoke-vnet.id
  allow_virtual_network_access      = true
  allow_forwarded_traffic           = false
  allow_gateway_transit             = true
  use_remote_gateways               = false

  depends_on                        = [azurerm_virtual_network_gateway.hub-vpngw]
}


#########################################################
# Bastion hosts
#########################################################

resource "azurerm_public_ip" "onprem-bastion-ip" {
  name                = "onprem-bastion-ip"
  location            = azurerm_resource_group.internet-outbound-microhack-rg.location
  resource_group_name = azurerm_resource_group.internet-outbound-microhack-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "onprem-bastion" {
  name                = "onprem-bastion"
  location            = azurerm_resource_group.internet-outbound-microhack-rg.location
  resource_group_name = azurerm_resource_group.internet-outbound-microhack-rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.onprem-bastion-subnet.id
    public_ip_address_id = azurerm_public_ip.onprem-bastion-ip.id
  }
}

resource "azurerm_public_ip" "wvd-spoke-bastion-ip" {
  name                = "wvd-spoke-bastion-ip"
  location            = azurerm_resource_group.internet-outbound-microhack-rg.location
  resource_group_name = azurerm_resource_group.internet-outbound-microhack-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "wvd-spoke-bastion" {
  name                = "wvd-spoke-bastion"
  location            = azurerm_resource_group.internet-outbound-microhack-rg.location
  resource_group_name = azurerm_resource_group.internet-outbound-microhack-rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.wvd-spoke-bastion-subnet.id
    public_ip_address_id = azurerm_public_ip.wvd-spoke-bastion-ip.id
  }
}
