# 🔥 Smart Environment Configuration and Local Values
locals {
  # Environment-based defaults
  environment_defaults = {
    dev = {
      node_count                  = 1
      machine_type                = "e2-standard-2"
      disk_size_gb                = 50
      preemptible                 = true
      enable_autoscaling          = true
      min_node_count              = 0
      max_node_count              = 3
      enable_autorepair           = true
      enable_autoupgrade          = false
      availability_type           = "ZONAL"
      enable_network_policy       = false
      enable_binary_authorization = false
    }
    staging = {
      node_count                  = 2
      machine_type                = "e2-standard-2"
      disk_size_gb                = 100
      preemptible                 = false
      enable_autoscaling          = true
      min_node_count              = 1
      max_node_count              = 5
      enable_autorepair           = true
      enable_autoupgrade          = true
      availability_type           = "REGIONAL"
      enable_network_policy       = true
      enable_binary_authorization = false
    }
    production = {
      node_count                  = 3
      machine_type                = "e2-standard-4"
      disk_size_gb                = 100
      preemptible                 = false
      enable_autoscaling          = true
      min_node_count              = 2
      max_node_count              = 10
      enable_autorepair           = true
      enable_autoupgrade          = true
      availability_type           = "REGIONAL"
      enable_network_policy       = true
      enable_binary_authorization = true
    }
  }

  # Merge environment defaults with user configuration
  env_config = local.environment_defaults[var.environment]

  # Final cluster configuration
  cluster_config = merge(local.env_config, {
    name                    = var.cluster_config.name
    location                = var.cluster_config.location != null ? var.cluster_config.location : var.region
    network                 = var.cluster_config.network
    subnetwork              = var.cluster_config.subnetwork
    pods_range_name         = var.cluster_config.pods_range_name
    services_range_name     = var.cluster_config.services_range_name
    enable_private_endpoint = var.cluster_config.enable_private_endpoint
    enable_private_nodes    = var.cluster_config.enable_private_nodes
    master_ipv4_cidr_block  = var.cluster_config.master_ipv4_cidr_block
  })

  # Service account configuration
  service_account_email = var.service_account_config.create_new ? google_service_account.gke_sa[0].email : var.service_account_config.email

  # Common labels for all resources
  common_labels = merge(var.tags, {
    cluster     = local.cluster_config.name
    environment = var.environment
    managed_by  = "terraform"
  })

  # Node pool defaults merged with environment config
  node_pool_defaults = merge(local.env_config, {
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  })
}
