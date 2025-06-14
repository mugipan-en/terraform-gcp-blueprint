# 🔥 GKE Node Pools Configuration

# Node Pools
resource "google_container_node_pool" "pools" {
  for_each = var.node_pools

  name     = "${local.cluster_config.name}-${each.key}"
  location = local.cluster_config.location
  cluster  = google_container_cluster.primary.name

  initial_node_count = each.value.initial_node_count

  # Autoscaling
  autoscaling {
    min_node_count = each.value.min_node_count
    max_node_count = each.value.max_node_count
  }

  # Management
  management {
    auto_repair  = each.value.auto_repair
    auto_upgrade = each.value.auto_upgrade
  }

  # Node configuration
  node_config {
    preemptible  = each.value.preemptible
    spot         = each.value.spot
    machine_type = each.value.machine_type
    disk_type    = each.value.disk_type
    disk_size_gb = each.value.disk_size_gb
    image_type   = each.value.image_type

    # Service account
    service_account = each.value.service_account_email != null ? each.value.service_account_email : local.service_account_email
    oauth_scopes    = each.value.oauth_scopes

    # Labels
    labels = merge(
      local.common_labels,
      each.value.labels,
      {
        pool = each.key
      }
    )

    # Metadata
    metadata = merge(
      local.node_pool_defaults.metadata,
      each.value.metadata
    )

    # Taints
    dynamic "taint" {
      for_each = each.value.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    # Shielded instance config
    shielded_instance_config {
      enable_secure_boot          = var.cluster_config.enable_shielded_nodes
      enable_integrity_monitoring = var.cluster_config.enable_shielded_nodes
    }

    # Network tags
    tags = ["gke-node", "${local.cluster_config.name}-node"]

    # Workload metadata config
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Local SSD configuration
    dynamic "local_ssd_config" {
      for_each = each.value.local_ssd_count > 0 ? [1] : []
      content {
        count = each.value.local_ssd_count
      }
    }

    # Guest accelerator (GPU) configuration
    dynamic "guest_accelerator" {
      for_each = each.value.gpu_type != null ? [1] : []
      content {
        type  = each.value.gpu_type
        count = each.value.gpu_count
      }
    }
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = each.value.max_surge
    max_unavailable = each.value.max_unavailable

    dynamic "blue_green_settings" {
      for_each = each.value.blue_green_update ? [1] : []
      content {
        standard_rollout_policy {
          batch_percentage    = 0.2
          batch_node_count    = 1
          batch_soak_duration = "10s"
        }
      }
    }
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  depends_on = [
    google_container_cluster.primary
  ]
}
