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

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "zone_or_region" {
  description = "Zone or region for the cluster (zone for zonal cluster, region for regional cluster)"
  type        = string
  default     = null
}

variable "network" {
  description = "VPC network name"
  type        = string
}

variable "subnetwork" {
  description = "VPC subnetwork name"
  type        = string
}

variable "pods_range_name" {
  description = "Name of the secondary range for pods"
  type        = string
}

variable "services_range_name" {
  description = "Name of the secondary range for services"
  type        = string
}

# Cluster configuration
variable "enable_private_endpoint" {
  description = "Enable private endpoint for the cluster master"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for the cluster master"
  type        = string
  default     = "172.16.0.0/28"
}

variable "enable_master_global_access" {
  description = "Enable global access to the cluster master"
  type        = bool
  default     = false
}

variable "master_authorized_networks" {
  description = "List of master authorized networks"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

# Node pool configuration
variable "initial_node_count" {
  description = "Initial number of nodes in the primary node pool"
  type        = number
  default     = 1
}

variable "min_node_count" {
  description = "Minimum number of nodes in the primary node pool"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes in the primary node pool"
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "Machine type for cluster nodes"
  type        = string
  default     = "e2-standard-2"
}

variable "disk_type" {
  description = "Disk type for cluster nodes"
  type        = string
  default     = "pd-standard"
}

variable "disk_size_gb" {
  description = "Disk size in GB for cluster nodes"
  type        = number
  default     = 100
}

variable "image_type" {
  description = "Image type for cluster nodes"
  type        = string
  default     = "COS_CONTAINERD"
}

variable "preemptible" {
  description = "Use preemptible instances for cluster nodes"
  type        = bool
  default     = false
}

variable "auto_repair" {
  description = "Enable auto repair for cluster nodes"
  type        = bool
  default     = true
}

variable "auto_upgrade" {
  description = "Enable auto upgrade for cluster nodes"
  type        = bool
  default     = true
}

variable "node_oauth_scopes" {
  description = "OAuth scopes for cluster nodes"
  type        = list(string)
  default = [
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/trace.append"
  ]
}

variable "node_tags" {
  description = "Network tags for cluster nodes"
  type        = list(string)
  default     = []
}

variable "node_taints" {
  description = "Taints for cluster nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

# Upgrade settings
variable "max_surge" {
  description = "Maximum number of nodes that can be created during upgrade"
  type        = number
  default     = 1
}

variable "max_unavailable" {
  description = "Maximum number of nodes that can be unavailable during upgrade"
  type        = number
  default     = 0
}

# Security
variable "enable_shielded_nodes" {
  description = "Enable shielded nodes"
  type        = bool
  default     = true
}

variable "enable_secure_boot" {
  description = "Enable secure boot for nodes"
  type        = bool
  default     = true
}

variable "enable_integrity_monitoring" {
  description = "Enable integrity monitoring for nodes"
  type        = bool
  default     = true
}

variable "enable_binary_authorization" {
  description = "Enable binary authorization"
  type        = bool
  default     = false
}

# Network policy
variable "enable_network_policy" {
  description = "Enable network policy"
  type        = bool
  default     = true
}

# Add-ons
variable "enable_http_load_balancing" {
  description = "Enable HTTP load balancing add-on"
  type        = bool
  default     = true
}

variable "enable_horizontal_pod_autoscaling" {
  description = "Enable horizontal pod autoscaling add-on"
  type        = bool
  default     = true
}

variable "enable_filestore_csi_driver" {
  description = "Enable Filestore CSI driver"
  type        = bool
  default     = false
}

variable "enable_gce_pd_csi_driver" {
  description = "Enable GCE Persistent Disk CSI driver"
  type        = bool
  default     = true
}

# Cluster autoscaling
variable "enable_cluster_autoscaling" {
  description = "Enable cluster autoscaling"
  type        = bool
  default     = false
}

variable "cluster_autoscaling_config" {
  description = "Cluster autoscaling configuration"
  type = object({
    cpu_min    = number
    cpu_max    = number
    memory_min = number
    memory_max = number
  })
  default = {
    cpu_min    = 1
    cpu_max    = 100
    memory_min = 1
    memory_max = 1000
  }
}

# Maintenance
variable "maintenance_start_time" {
  description = "Start time for daily maintenance window (HH:MM format)"
  type        = string
  default     = "03:00"
}

variable "release_channel" {
  description = "Release channel for GKE cluster"
  type        = string
  default     = "STABLE"
  
  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "Release channel must be one of: RAPID, REGULAR, STABLE."
  }
}

# Logging and monitoring
variable "logging_service" {
  description = "Logging service for the cluster"
  type        = string
  default     = "logging.googleapis.com/kubernetes"
}

variable "monitoring_service" {
  description = "Monitoring service for the cluster"
  type        = string
  default     = "monitoring.googleapis.com/kubernetes"
}

# Additional node pools
variable "additional_node_pools" {
  description = "Map of additional node pools"
  type = map(object({
    initial_node_count          = number
    min_node_count              = number
    max_node_count              = number
    machine_type                = string
    disk_type                   = string
    disk_size_gb                = number
    image_type                  = string
    preemptible                 = bool
    auto_repair                 = bool
    auto_upgrade                = bool
    max_surge                   = number
    max_unavailable             = number
    enable_secure_boot          = bool
    enable_integrity_monitoring = bool
    labels                      = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    additional_tags = list(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}