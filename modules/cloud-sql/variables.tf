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

variable "database_name" {
  description = "Name of the database"
  type        = string
}

variable "database_version" {
  description = "Database version"
  type        = string
  default     = "POSTGRES_14"
  
  validation {
    condition = contains([
      "POSTGRES_9_6", "POSTGRES_10", "POSTGRES_11", "POSTGRES_12", "POSTGRES_13", "POSTGRES_14", "POSTGRES_15",
      "MYSQL_5_6", "MYSQL_5_7", "MYSQL_8_0",
      "SQLSERVER_2017_STANDARD", "SQLSERVER_2017_ENTERPRISE", "SQLSERVER_2017_EXPRESS", "SQLSERVER_2017_WEB",
      "SQLSERVER_2019_STANDARD", "SQLSERVER_2019_ENTERPRISE", "SQLSERVER_2019_EXPRESS", "SQLSERVER_2019_WEB"
    ], var.database_version)
    error_message = "Invalid database version specified."
  }
}

variable "instance_type" {
  description = "Cloud SQL instance type"
  type        = string
  default     = "db-f1-micro"
}

variable "availability_type" {
  description = "Availability type for the instance"
  type        = string
  default     = "ZONAL"
  
  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.availability_type)
    error_message = "Availability type must be either ZONAL or REGIONAL."
  }
}

variable "disk_type" {
  description = "Disk type for the instance"
  type        = string
  default     = "PD_SSD"
  
  validation {
    condition     = contains(["PD_SSD", "PD_HDD"], var.disk_type)
    error_message = "Disk type must be either PD_SSD or PD_HDD."
  }
}

variable "disk_size_gb" {
  description = "Disk size in GB"
  type        = number
  default     = 20
  
  validation {
    condition     = var.disk_size_gb >= 10 && var.disk_size_gb <= 65536
    error_message = "Disk size must be between 10 and 65536 GB."
  }
}

variable "disk_autoresize" {
  description = "Enable automatic disk resize"
  type        = bool
  default     = true
}

variable "disk_autoresize_limit" {
  description = "Maximum disk size for autoresize (0 = no limit)"
  type        = number
  default     = 0
}

variable "network" {
  description = "VPC network for private IP"
  type        = string
  default     = null
}

variable "ipv4_enabled" {
  description = "Enable IPv4 for the instance"
  type        = bool
  default     = false
}

variable "require_ssl" {
  description = "Require SSL for connections"
  type        = bool
  default     = true
}

variable "authorized_networks" {
  description = "List of authorized networks"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# Backup configuration
variable "backup_enabled" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_start_time" {
  description = "Start time for daily backup (HH:MM format)"
  type        = string
  default     = "03:00"
}

variable "backup_location" {
  description = "Location for backups"
  type        = string
  default     = null
}

variable "point_in_time_recovery_enabled" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = true
}

variable "transaction_log_retention_days" {
  description = "Number of days to retain transaction logs"
  type        = number
  default     = 7
}

variable "retained_backups" {
  description = "Number of backups to retain"
  type        = number
  default     = 7
}

# Maintenance window
variable "maintenance_window_day" {
  description = "Day of the week for maintenance (1-7, 1=Monday)"
  type        = number
  default     = 7
  
  validation {
    condition     = var.maintenance_window_day >= 1 && var.maintenance_window_day <= 7
    error_message = "Maintenance window day must be between 1 and 7."
  }
}

variable "maintenance_window_hour" {
  description = "Hour of the day for maintenance (0-23)"
  type        = number
  default     = 3
  
  validation {
    condition     = var.maintenance_window_hour >= 0 && var.maintenance_window_hour <= 23
    error_message = "Maintenance window hour must be between 0 and 23."
  }
}

variable "maintenance_window_update_track" {
  description = "Update track for maintenance"
  type        = string
  default     = "stable"
  
  validation {
    condition     = contains(["canary", "stable"], var.maintenance_window_update_track)
    error_message = "Update track must be either 'canary' or 'stable'."
  }
}

# Database flags
variable "database_flags" {
  description = "List of database flags"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# Query insights
variable "query_insights_enabled" {
  description = "Enable query insights"
  type        = bool
  default     = true
}

variable "query_string_length" {
  description = "Maximum query string length for insights"
  type        = number
  default     = 1024
}

variable "record_application_tags" {
  description = "Record application tags in query insights"
  type        = bool
  default     = false
}

variable "record_client_address" {
  description = "Record client address in query insights"
  type        = bool
  default     = false
}

# Database configuration
variable "charset" {
  description = "Database charset"
  type        = string
  default     = "UTF8"
}

variable "collation" {
  description = "Database collation"
  type        = string
  default     = "en_US.UTF8"
}

variable "additional_databases" {
  description = "List of additional databases to create"
  type        = list(string)
  default     = []
}

# Users
variable "default_user_name" {
  description = "Name of the default database user"
  type        = string
  default     = "admin"
}

variable "default_user_password" {
  description = "Password for the default user (if null, random password will be generated)"
  type        = string
  default     = null
  sensitive   = true
}

variable "database_users" {
  description = "Map of database users to create"
  type = map(object({
    password = string
    host     = string
    password_policy = object({
      allowed_failed_attempts      = number
      password_expiration_duration = string
      enable_failed_attempts_check = bool
      enable_password_verification = bool
    })
  }))
  default = {}
  sensitive = true
}

# Read replicas
variable "read_replicas" {
  description = "Map of read replicas to create"
  type = map(object({
    region          = string
    tier            = string
    failover_target = bool
  }))
  default = {}
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}