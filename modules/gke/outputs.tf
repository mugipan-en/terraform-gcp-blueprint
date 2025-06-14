output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_id" {
  description = "ID of the GKE cluster"
  value       = google_container_cluster.primary.id
}

output "cluster_endpoint" {
  description = "Endpoint of the GKE cluster"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "CA certificate of the GKE cluster"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "Location of the GKE cluster"
  value       = google_container_cluster.primary.location
}

output "cluster_master_version" {
  description = "Master version of the GKE cluster"
  value       = google_container_cluster.primary.master_version
}

output "cluster_node_version" {
  description = "Node version of the GKE cluster"
  value       = google_container_cluster.primary.node_version
}

output "cluster_status" {
  description = "Status of the GKE cluster"
  value       = google_container_cluster.primary.status
}

output "cluster_services_ipv4_cidr" {
  description = "Services IPv4 CIDR of the GKE cluster"
  value       = google_container_cluster.primary.services_ipv4_cidr
}

output "cluster_self_link" {
  description = "Self link of the GKE cluster"
  value       = google_container_cluster.primary.self_link
}

output "primary_node_pool_name" {
  description = "Name of the primary node pool"
  value       = google_container_node_pool.primary_nodes.name
}

output "primary_node_pool_instance_group_urls" {
  description = "Instance group URLs of the primary node pool"
  value       = google_container_node_pool.primary_nodes.instance_group_urls
}

output "additional_node_pools" {
  description = "Information about additional node pools"
  value = {
    for k, v in google_container_node_pool.additional_pools : k => {
      name                        = v.name
      instance_group_urls         = v.instance_group_urls
      managed_instance_group_urls = v.managed_instance_group_urls
    }
  }
}

output "service_account_email" {
  description = "Email of the GKE service account"
  value       = google_service_account.gke_sa.email
}

output "service_account_name" {
  description = "Name of the GKE service account"
  value       = google_service_account.gke_sa.name
}

# Kubernetes configuration outputs
output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${google_container_cluster.primary.location} --project ${var.project_id}"
}

output "kubectl_config" {
  description = "Kubectl configuration for the cluster"
  value = {
    host                   = "https://${google_container_cluster.primary.endpoint}"
    cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
    cluster_name           = google_container_cluster.primary.name
    project_id             = var.project_id
    location               = google_container_cluster.primary.location
  }
  sensitive = true
}
