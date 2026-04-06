# ---------------------------------------------------------------------------
# VNet Hub
# ---------------------------------------------------------------------------
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${var.name_prefix}-hub"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# ---------------------------------------------------------------------------
# Subnet — Container Apps Environment
# Requer delegação para Microsoft.App/environments e mínimo /23
# ---------------------------------------------------------------------------
resource "azurerm_subnet" "container_apps" {
  name                 = "snet-${var.name_prefix}-cae"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_container_apps_cidr]

  delegation {
    name = "delegation-container-apps"
    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# ---------------------------------------------------------------------------
# Subnet — Private Endpoints (Storage, etc.)
# ---------------------------------------------------------------------------
resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-${var.name_prefix}-pe"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_private_endpoints_cidr]
}

# ---------------------------------------------------------------------------
# NSG — Container Apps
# ---------------------------------------------------------------------------
resource "azurerm_network_security_group" "container_apps" {
  name                = "nsg-${var.name_prefix}-cae"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  # Permite tráfego interno entre pods/envs Container Apps
  security_rule {
    name                       = "AllowContainerAppsInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.subnet_container_apps_cidr
    destination_address_prefix = var.subnet_container_apps_cidr
  }

  # Permite acesso HTTPS de qualquer origem (Grafana UI pública)
  security_rule {
    name                       = "AllowHTTPSInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # OTLP gRPC (4317) e HTTP (4318) para telemetria
  security_rule {
    name                       = "AllowOTLPInbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["4317", "4318"]
    source_address_prefix      = "*"
    destination_address_prefix = var.subnet_container_apps_cidr
  }
}

resource "azurerm_subnet_network_security_group_association" "container_apps" {
  subnet_id                 = azurerm_subnet.container_apps.id
  network_security_group_id = azurerm_network_security_group.container_apps.id
}

# ---------------------------------------------------------------------------
# Private DNS Zone — blob.core.windows.net (Storage Account)
# ---------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "pdnslink-${var.name_prefix}-blob"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = var.tags
}
