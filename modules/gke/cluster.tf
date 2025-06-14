# 🔥 GKE Cluster Configuration

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = local.cluster_config.name
  location = local.cluster_config.location

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = local.cluster_config.network
  subnetwork = local.cluster_config.subnetwork

  # Network configuration
  ip_allocation_policy {
    cluster_secondary_range_name  = local.cluster_config.pods_range_name
    services_secondary_range_name = local.cluster_config.services_range_name
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = local.cluster_config.enable_private_nodes
    enable_private_endpoint = local.cluster_config.enable_private_endpoint
    master_ipv4_cidr_block  = local.cluster_config.master_ipv4_cidr_block

    master_global_access_config {
      enabled = var.cluster_config.enable_master_global_access
    }
  }

  # Master authorized networks
  dynamic "master_authorized_networks_config" {
    for_each = length(var.advanced_config.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.advanced_config.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Network policy
  network_policy {
    enabled  = local.cluster_config.enable_network_policy
    provider = local.cluster_config.enable_network_policy ? var.advanced_config.network_policy_provider : null
  }

  # Addons
  addons_config {
    http_load_balancing {
      disabled = !var.cluster_config.enable_http_load_balancing
    }

    horizontal_pod_autoscaling {
      disabled = !var.cluster_config.enable_horizontal_pod_autoscaling
    }

    network_policy_config {
      disabled = !local.cluster_config.enable_network_policy
    }

    gcp_filestore_csi_driver_config {
      enabled = var.cluster_config.enable_filestore_csi_driver
    }

    gce_persistent_disk_csi_driver_config {
      enabled = var.cluster_config.enable_gce_pd_csi_driver
    }
  }

  # Cluster autoscaling
  dynamic "cluster_autoscaling" {
    for_each = var.cost_optimization.enable_node_auto_provisioning ? [1] : []
    content {
      enabled = true
      resource_limits {
        resource_type = "cpu"
        minimum       = 1
        maximum       = 100
      }
      resource_limits {
        resource_type = "memory"
        minimum       = 1
        maximum       = 1000
      }
      auto_provisioning_defaults {
        oauth_scopes     = local.node_pool_defaults.oauth_scopes
        service_account  = local.service_account_email
        min_cpu_platform = var.cost_optimization.auto_provisioning_defaults.min_cpu_platform
      }
    }
  }

  # Maintenance policy
  maintenance_policy {
    daily_maintenance_window {
      start_time = var.cluster_config.maintenance_start_time
    }

    recurring_window {
      start_time = "${var.cluster_config.maintenance_start_time}:00"
      end_time   = var.cluster_config.maintenance_end_time
      recurrence = var.cluster_config.maintenance_recurrence
    }
  }

  # Release channel
  release_channel {
    channel = var.cluster_config.release_channel
  }

  # Logging and monitoring
  logging_config {
    enable_components = var.cluster_config.logging_components
  }

  monitoring_config {
    enable_components = var.cluster_config.monitoring_components
  }

  # Security configurations
  enable_shielded_nodes = var.cluster_config.enable_shielded_nodes

  # Binary authorization
  dynamic "binary_authorization" {
    for_each = local.cluster_config.enable_binary_authorization ? [1] : []
    content {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
    }
  }

  # Resource usage export
  dynamic "resource_usage_export_config" {
    for_each = var.advanced_config.enable_resource_consumption_export ? [1] : []
    content {
      enable_network_egress_metering       = true
      enable_resource_consumption_metering = true

      bigquery_destination {
        dataset_id = var.advanced_config.resource_consumption_bigquery_dataset
      }
    }
  }

  # Database encryption
  dynamic "database_encryption" {
    for_each = var.advanced_config.database_encryption_state == "ENCRYPTED" ? [1] : []
    content {
      state    = var.advanced_config.database_encryption_state
      key_name = var.advanced_config.database_encryption_key_name
    }
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  depends_on = [
    google_project_iam_member.gke_sa_roles
  ]
}
