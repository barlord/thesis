# Generate random resource group name
resource "random_pet" "rg_name" {
    for_each = toset(var.regions)
    prefix   = "${var.resource_group_name_prefix}-${each.key}"
}
resource "azurerm_resource_group" "rg" {
    for_each = toset(var.regions)
    location = each.key
    name     = random_pet.rg_name[each.key].id
}

resource "random_pet" "azurerm_kubernetes_cluster_name" {
    for_each = toset(var.regions)
    prefix   = "cluster"
}

resource "random_pet" "azurerm_kubernetes_cluster_dns_prefix" {
    for_each = toset(var.regions)
    prefix   = "dns"
}

#not unique 0.3% chacne of collison (for 3)
resource "random_integer" "vnet_netnum" {
    for_each = toset(var.regions)
    min      = 0
    max      = 254  # Adjust this value based on the number of unique VNet numbers you need (should be greater then number of regions)
}
#not unique 0.3% chance of collison (for 3)
resource "random_integer" "subnet_netnum" {
    for_each = toset(var.regions)
    min      = 0
    max      = 254  # Adjust this value based on the number of unique subnet numbers you need
}

# Define the virtual network
resource "azurerm_virtual_network" "az_vnet" {
    for_each            = toset(var.regions)
    name                = "${var.vnet_name}-${each.key}"
    location            = each.key
    resource_group_name = azurerm_resource_group.rg[each.key].name
    address_space       = ["10.${random_integer.vnet_netnum[each.key].result}.0.0/16"]
}

# Define the subnet for Microsoft.Storage.Global
resource "azurerm_subnet" "az_subnet_storage_global" {
    for_each             = toset(var.regions)
    name                 = "${var.subnet_name}-storage-global-${each.key}"
    resource_group_name  = azurerm_resource_group.rg[each.key].name
    virtual_network_name = azurerm_virtual_network.az_vnet[each.key].name
    address_prefixes     = ["10.${random_integer.vnet_netnum[each.key].result }.${random_integer.subnet_netnum[each.key].result + 1}.0/24"]
    service_endpoints    = ["Microsoft.Storage.Global"]
}


resource "azurerm_virtual_network_peering" "vnet_peering" {
    for_each = { for k, v in local.vnet_peering_pairs : "${k}" => v }

    name                       = "peer-${each.value.source}-${each.value.target}"
    resource_group_name        = azurerm_resource_group.rg[each.value.source].name
    virtual_network_name       = azurerm_virtual_network.az_vnet[each.value.source].name
    remote_virtual_network_id  = azurerm_virtual_network.az_vnet[each.value.target].id
    allow_virtual_network_access = true
    allow_forwarded_traffic    = true
    allow_gateway_transit      = false
    use_remote_gateways        = false
}

resource "azurerm_kubernetes_cluster" "k8s" {
    for_each            = toset(var.regions)
    location            = each.key
    name                = random_pet.azurerm_kubernetes_cluster_name[each.key].id
    resource_group_name = azurerm_resource_group.rg[each.key].name
    dns_prefix          = random_pet.azurerm_kubernetes_cluster_dns_prefix[each.key].id

    identity {
        type = "SystemAssigned"
    }

    default_node_pool {
        name            = "agentpool"
        vm_size         = "Standard_B2ms"
        node_count      = var.node_count
        vnet_subnet_id  = azurerm_subnet.az_subnet_storage_global[each.key].id
    }

    linux_profile {
        admin_username = var.username

        ssh_key {
              key_data = azapi_resource_action.ssh_public_key_gen[each.key].output.publicKey
                }
    }

    network_profile {
        network_plugin    = "kubenet"
        load_balancer_sku = "standard"
        service_cidr      = "10.${random_integer.vnet_netnum[each.key].result + 1}.0.0/16"  # Adding 1 to avoid overlap
        dns_service_ip    = "10.${random_integer.vnet_netnum[each.key].result + 1}.0.10"
    }

    storage_profile {
        blob_driver_enabled = true  # Set to true for NFS access
    }
}

# Retrieve the public IP address at runtime
data "http" "my_ip" {
    url = "https://api.ipify.org?format=text"
}


# Create a storage account with NFS enabled
resource "azurerm_storage_account" "storage" {
    for_each                  = toset(var.regions)
    name                      = "sathesis${each.key}"
    resource_group_name       = azurerm_resource_group.rg[each.key].name
    location                  = each.key
    account_tier              = "Standard"
    account_replication_type  = "LRS"
    is_hns_enabled            = true
    account_kind              = "StorageV2"
    access_tier               = "Hot"
    min_tls_version           = "TLS1_2"
    nfsv3_enabled             = true

    blob_properties {
        delete_retention_policy {
            days = 7
        }
    }

    network_rules {
        default_action             = "Deny"
        bypass                     = ["AzureServices"]
        ip_rules                   = [data.http.my_ip.body]  # Allow access from pc's IP
        virtual_network_subnet_ids = [azurerm_subnet.az_subnet_storage_global[each.key].id]  # Allow access from AKS subnet
    }
}

# Define storage container
resource "azurerm_storage_container" "testblob" {
    for_each              = toset(var.regions)
    name                  = "testblob"
    storage_account_name  = azurerm_storage_account.storage[each.key].name
    container_access_type = "private"
}