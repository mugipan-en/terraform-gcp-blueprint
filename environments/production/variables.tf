variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "asia-northeast1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "asia-northeast1-a"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "subnet_cidrs" {
  description = "CIDR blocks for subnets"
  type = object({
    public  = string
    private = string
  })
}

variable "gke_cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "gke_node_count" {
  description = "Number of nodes in the GKE cluster"
  type        = number
  default     = 2
}

variable "gke_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-standard-2"
}

variable "gke_disk_size_gb" {
  description = "Disk size for GKE nodes in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the Cloud SQL database"
  type        = string
}

variable "db_instance_type" {
  description = "Instance type for Cloud SQL"
  type        = string
  default     = "db-f1-micro"
}

variable "db_version" {
  description = "Database version"
  type        = string
  default     = "POSTGRES_15"
}

variable "storage_bucket_names" {
  description = "List of Cloud Storage bucket names"
  type        = list(string)
  default     = []
}

variable "service_accounts" {
  description = "List of service accounts to create"
  type = list(object({
    account_id   = string
    display_name = string
    roles        = list(string)
  }))
  default = []
}

variable "notification_channels" {
  description = "List of notification channels for monitoring"
  type = list(object({
    display_name = string
    type         = string
    labels       = map(string)
  }))
  default = []
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
