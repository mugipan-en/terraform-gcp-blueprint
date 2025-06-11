# GKE Service Account
resource "google_service_account" "gke_sa" {
  account_id   = "${var.name_prefix}-gke-sa"
  display_name = "GKE Service Account for ${var.name_prefix}"
  description  = "Service account for GKE cluster nodes"
}

# IAM roles for GKE service account
resource "google_project_iam_member" "gke_sa_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/storage.objectViewer"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone_or_region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network
  subnetwork = var.subnetwork

  # Network configuration
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block

    master_global_access_config {
      enabled = var.enable_master_global_access
    }
  }

  # Master authorized networks
  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
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
    enabled  = var.enable_network_policy
    provider = var.enable_network_policy ? "CALICO" : null
  }

  # Addons
  addons_config {
    http_load_balancing {
      disabled = !var.enable_http_load_balancing
    }

    horizontal_pod_autoscaling {
      disabled = !var.enable_horizontal_pod_autoscaling
    }

    network_policy_config {
      disabled = !var.enable_network_policy
    }

    gcp_filestore_csi_driver_config {
      enabled = var.enable_filestore_csi_driver
    }

    gce_persistent_disk_csi_driver_config {
      enabled = var.enable_gce_pd_csi_driver
    }
  }

  # Cluster autoscaling
  dynamic "cluster_autoscaling" {
    for_each = var.enable_cluster_autoscaling ? [1] : []
    content {
      enabled = true
      resource_limits {
        resource_type = "cpu"
        minimum       = var.cluster_autoscaling_config.cpu_min
        maximum       = var.cluster_autoscaling_config.cpu_max
      }
      resource_limits {
        resource_type = "memory"
        minimum       = var.cluster_autoscaling_config.memory_min
        maximum       = var.cluster_autoscaling_config.memory_max
      }
      auto_provisioning_defaults {
        oauth_scopes = var.node_oauth_scopes
        service_account = google_service_account.gke_sa.email
      }
    }
  }

  # Maintenance policy
  maintenance_policy {
    daily_maintenance_window {
      start_time = var.maintenance_start_time
    }
  }

  # Release channel
  release_channel {
    channel = var.release_channel
  }

  # Logging and monitoring
  logging_service    = var.logging_service
  monitoring_service = var.monitoring_service

  # Security configurations
  enable_shielded_nodes = var.enable_shielded_nodes

  # Binary authorization
  dynamic "binary_authorization" {
    for_each = var.enable_binary_authorization ? [1] : []
    content {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
    }
  }

  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }

  depends_on = [
    google_project_iam_member.gke_sa_roles
  ]
}

# Primary Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-primary-pool"
  location   = var.zone_or_region
  cluster    = google_container_cluster.primary.name
  
  initial_node_count = var.initial_node_count

  # Autoscaling
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  # Management
  management {
    auto_repair  = var.auto_repair
    auto_upgrade = var.auto_upgrade
  }

  # Node configuration
  node_config {
    preemptible  = var.preemptible
    machine_type = var.machine_type
    disk_type    = var.disk_type
    disk_size_gb = var.disk_size_gb
    image_type   = var.image_type

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.gke_sa.email
    oauth_scopes    = var.node_oauth_scopes

    # Labels
    labels = merge(var.tags, {
      cluster = var.cluster_name
      pool    = "primary"
    })

    # Metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Taints
    dynamic "taint" {
      for_each = var.node_taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    # Shielded instance config
    shielded_instance_config {
      enable_secure_boot          = var.enable_secure_boot
      enable_integrity_monitoring = var.enable_integrity_monitoring
    }

    # Network tags
    tags = var.node_tags
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = var.max_surge
    max_unavailable = var.max_unavailable
  }

  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }
}

# Additional node pools
resource "google_container_node_pool" "additional_pools" {
  for_each = var.additional_node_pools

  name       = "${var.cluster_name}-${each.key}-pool"
  location   = var.zone_or_region
  cluster    = google_container_cluster.primary.name
  
  initial_node_count = each.value.initial_node_count

  autoscaling {
    min_node_count = each.value.min_node_count
    max_node_count = each.value.max_node_count
  }

  management {
    auto_repair  = each.value.auto_repair
    auto_upgrade = each.value.auto_upgrade
  }

  node_config {
    preemptible  = each.value.preemptible
    machine_type = each.value.machine_type
    disk_type    = each.value.disk_type
    disk_size_gb = each.value.disk_size_gb
    image_type   = each.value.image_type

    service_account = google_service_account.gke_sa.email
    oauth_scopes    = var.node_oauth_scopes

    labels = merge(var.tags, each.value.labels, {
      cluster = var.cluster_name
      pool    = each.key
    })

    metadata = {
      disable-legacy-endpoints = "true"
    }

    dynamic "taint" {
      for_each = each.value.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    shielded_instance_config {
      enable_secure_boot          = each.value.enable_secure_boot
      enable_integrity_monitoring = each.value.enable_integrity_monitoring
    }

    tags = concat(var.node_tags, each.value.additional_tags)
  }

  upgrade_settings {
    max_surge       = each.value.max_surge
    max_unavailable = each.value.max_unavailable
  }

  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }
}