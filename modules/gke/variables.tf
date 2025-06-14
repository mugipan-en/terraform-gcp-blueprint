# Basic Configuration
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

# 🔥 Modern Cluster Configuration
variable "cluster_config" {
  description = "Comprehensive GKE cluster configuration"
  type = object({
    name       = string
    location   = optional(string)
    network    = string
    subnetwork = string

    # Network ranges
    pods_range_name     = optional(string, "gke-pods")
    services_range_name = optional(string, "gke-services")

    # Privacy & Security
    enable_private_endpoint = optional(bool, true)
    enable_private_nodes    = optional(bool, true)
    master_ipv4_cidr_block  = optional(string, "172.16.0.0/28")

    # Features
    enable_network_policy       = optional(bool, true)
    enable_workload_identity    = optional(bool, true)
    enable_shielded_nodes       = optional(bool, true)
    enable_binary_authorization = optional(bool, false)

    # Logging & Monitoring
    logging_components    = optional(list(string), ["SYSTEM_COMPONENTS", "WORKLOADS"])
    monitoring_components = optional(list(string), ["SYSTEM_COMPONENTS", "WORKLOADS"])

    # Maintenance
    maintenance_start_time = optional(string, "03:00")
    maintenance_end_time   = optional(string, "07:00")
    maintenance_recurrence = optional(string, "FREQ=WEEKLY;BYDAY=SA")

    # Addons
    enable_http_load_balancing        = optional(bool, true)
    enable_horizontal_pod_autoscaling = optional(bool, true)
    enable_kubernetes_alpha           = optional(bool, false)
    enable_istio                      = optional(bool, false)
  })

  validation {
    condition     = can(cidrhost(var.cluster_config.master_ipv4_cidr_block, 0))
    error_message = "master_ipv4_cidr_block must be a valid CIDR block."
  }

  validation {
    condition     = length(var.cluster_config.name) <= 40
    error_message = "Cluster name must be 40 characters or less."
  }
}

# 🔥 Modern Node Pool Configuration
variable "node_pools" {
  description = "Node pool configurations with smart defaults"
  type = map(object({
    # Basic Configuration
    machine_type = optional(string, "e2-standard-4")
    disk_size_gb = optional(number, 100)
    disk_type    = optional(string, "pd-standard")
    image_type   = optional(string, "COS_CONTAINERD")

    # Scaling
    initial_node_count = optional(number, 1)
    min_node_count     = optional(number, 1)
    max_node_count     = optional(number, 10)

    # Node Management
    auto_repair  = optional(bool, true)
    auto_upgrade = optional(bool, true)
    preemptible  = optional(bool, false)
    spot         = optional(bool, false)

    # Networking
    enable_ip_alias = optional(bool, true)

    # Security
    service_account_email = optional(string)
    oauth_scopes = optional(list(string), [
      "https://www.googleapis.com/auth/cloud-platform"
    ])

    # Taints
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])

    # Labels
    labels = optional(map(string), {})

    # Metadata
    metadata = optional(map(string), {
      disable-legacy-endpoints = "true"
    })
  }))
  default = {
    default = {}
  }

  validation {
    condition = alltrue([
      for pool_name, config in var.node_pools :
      config.min_node_count <= config.max_node_count
    ])
    error_message = "min_node_count must be less than or equal to max_node_count for all node pools."
  }
}

# 🔥 Modern Service Account Configuration
variable "service_account_config" {
  description = "Service account configuration for GKE"
  type = object({
    create_new = optional(bool, true)
    email      = optional(string)

    # Workload Identity
    enable_workload_identity   = optional(bool, true)
    kubernetes_namespace       = optional(string, "default")
    kubernetes_service_account = optional(string, "default")

    # IAM Roles
    additional_roles = optional(list(string), [
      "roles/monitoring.metricWriter",
      "roles/monitoring.viewer",
      "roles/logging.logWriter"
    ])
  })
  default = {}
}

# Environment-aware Defaults
variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

# Resource Tagging
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Advanced Features
variable "advanced_config" {
  description = "Advanced GKE configuration options"
  type = object({
    # Network Policy
    network_policy_provider = optional(string, "CALICO")

    # Resource Usage Export
    enable_resource_consumption_export    = optional(bool, false)
    resource_consumption_bigquery_dataset = optional(string)

    # Database Encryption
    database_encryption_state    = optional(string, "DECRYPTED")
    database_encryption_key_name = optional(string)

    # Master Auth
    enable_legacy_abac = optional(bool, false)

    # IP Allocation Policy
    cluster_ipv4_cidr_block  = optional(string)
    services_ipv4_cidr_block = optional(string)

    # Private Cluster Config
    enable_private_nodes = optional(bool, true)
    master_authorized_networks = optional(list(object({
      cidr_block   = string
      display_name = optional(string)
    })), [])
  })
  default = {}
}

# Cost Optimization
variable "cost_optimization" {
  description = "Cost optimization settings"
  type = object({
    enable_preemptible_nodes = optional(bool, false)
    enable_spot_nodes        = optional(bool, false)
    auto_scaling_enabled     = optional(bool, true)

    # Node auto-provisioning
    enable_node_auto_provisioning = optional(bool, false)
    max_pods_per_node             = optional(number, 110)

    # Resource limits for auto-provisioning
    auto_provisioning_defaults = optional(object({
      min_cpu_platform = optional(string, "Intel Skylake")
      oauth_scopes = optional(list(string), [
        "https://www.googleapis.com/auth/cloud-platform"
      ])
    }))
  })
  default = {}
}
