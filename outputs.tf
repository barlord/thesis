output "resource_group_name" {
  value = { for k, v in azurerm_resource_group.rg : k => v.name }
}

output "kubernetes_cluster_name" {
  value = { for k, v in azurerm_kubernetes_cluster.k8s : k => v.name }
}

output "client_certificate" {
  value     = { for k, v in azurerm_kubernetes_cluster.k8s : k => v.kube_config[0].client_certificate }
  sensitive = true
}

output "client_key" {
  value     = { for k, v in azurerm_kubernetes_cluster.k8s : k => v.kube_config[0].client_key }
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = { for k, v in azurerm_kubernetes_cluster.k8s : k => v.kube_config[0].cluster_ca_certificate }
  sensitive = true
}

output "cluster_password" {
  value     = { for k, v in azurerm_kubernetes_cluster.k8s : k => v.kube_config[0].password }
  sensitive = true
}

output "cluster_username" {
  value     = { for k, v in azurerm_kubernetes_cluster.k8s : k => v.kube_config[0].username }
  sensitive = true
}

output "host" {
  value     = { for k, v in azurerm_kubernetes_cluster.k8s : k => v.kube_config[0].host }
  sensitive = true
}

output "kube_config" {
  value     = { for k, v in azurerm_kubernetes_cluster.k8s : k => v.kube_config_raw }
  sensitive = true
}

output "aks_subnet_id" {
  value = { for k, v in azurerm_subnet.az_subnet : k => v.id }
}