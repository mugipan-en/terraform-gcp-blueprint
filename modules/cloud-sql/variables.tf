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

# 🔥 Modern Database Configuration
variable "database_config" {
  description = "Comprehensive Cloud SQL database configuration"
  type = object({
    name             = string
    database_version = optional(string, "POSTGRES_15")

    # Instance Configuration
    instance_type       = optional(string, "db-f1-micro")
    availability_type   = optional(string, "ZONAL")
    deletion_protection = optional(bool, true)

    # Storage Configuration
    disk_type             = optional(string, "PD_SSD")
    disk_size_gb          = optional(number, 20)
    disk_autoresize       = optional(bool, true)
    disk_autoresize_limit = optional(number, 0)

    # Network Configuration
    network      = optional(string)
    ipv4_enabled = optional(bool, false)
    require_ssl  = optional(bool, true)
    authorized_networks = optional(list(object({
      name  = string
      value = string
    })), [])

    # Database Settings
    charset              = optional(string, "UTF8")
    collation            = optional(string, "en_US.UTF8")
    additional_databases = optional(list(string), [])

    # Database Flags
    database_flags = optional(list(object({
      name  = string
      value = string
    })), [])
  })

  validation {
    condition = contains([
      "POSTGRES_9_6", "POSTGRES_10", "POSTGRES_11", "POSTGRES_12", "POSTGRES_13", "POSTGRES_14", "POSTGRES_15",
      "MYSQL_5_6", "MYSQL_5_7", "MYSQL_8_0",
      "SQLSERVER_2017_STANDARD", "SQLSERVER_2017_ENTERPRISE", "SQLSERVER_2017_EXPRESS", "SQLSERVER_2017_WEB",
      "SQLSERVER_2019_STANDARD", "SQLSERVER_2019_ENTERPRISE", "SQLSERVER_2019_EXPRESS", "SQLSERVER_2019_WEB"
    ], var.database_config.database_version)
    error_message = "Invalid database version specified."
  }

  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.database_config.availability_type)
    error_message = "Availability type must be either ZONAL or REGIONAL."
  }

  validation {
    condition     = contains(["PD_SSD", "PD_HDD"], var.database_config.disk_type)
    error_message = "Disk type must be either PD_SSD or PD_HDD."
  }

  validation {
    condition     = var.database_config.disk_size_gb >= 10 && var.database_config.disk_size_gb <= 65536
    error_message = "Disk size must be between 10 and 65536 GB."
  }
}

# 🔥 Modern Backup Configuration
variable "backup_config" {
  description = "Backup and recovery configuration"
  type = object({
    enabled                        = optional(bool, true)
    start_time                     = optional(string, "03:00")
    location                       = optional(string)
    point_in_time_recovery_enabled = optional(bool, true)
    transaction_log_retention_days = optional(number, 7)
    retained_backups               = optional(number, 7)

    # Binary Log Settings
    binary_log_enabled = optional(bool, true)
  })
  default = {}

  validation {
    condition     = can(regex("^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$", var.backup_config.start_time))
    error_message = "Backup start time must be in HH:MM format (24-hour)."
  }

  validation {
    condition     = var.backup_config.transaction_log_retention_days >= 1 && var.backup_config.transaction_log_retention_days <= 365
    error_message = "Transaction log retention days must be between 1 and 365."
  }
}

# 🔥 Modern Maintenance Configuration
variable "maintenance_config" {
  description = "Maintenance window configuration"
  type = object({
    day          = optional(number, 7) # Sunday
    hour         = optional(number, 3) # 3 AM
    update_track = optional(string, "stable")
  })
  default = {}

  validation {
    condition     = var.maintenance_config.day >= 1 && var.maintenance_config.day <= 7
    error_message = "Maintenance window day must be between 1 and 7 (1=Monday, 7=Sunday)."
  }

  validation {
    condition     = var.maintenance_config.hour >= 0 && var.maintenance_config.hour <= 23
    error_message = "Maintenance window hour must be between 0 and 23."
  }

  validation {
    condition     = contains(["canary", "stable"], var.maintenance_config.update_track)
    error_message = "Update track must be either 'canary' or 'stable'."
  }
}

# 🔥 Modern Query Insights Configuration
variable "query_insights_config" {
  description = "Query insights and monitoring configuration"
  type = object({
    enabled                 = optional(bool, true)
    query_string_length     = optional(number, 1024)
    record_application_tags = optional(bool, false)
    record_client_address   = optional(bool, false)
    query_plans_per_minute  = optional(number, 5)
  })
  default = {}

  validation {
    condition     = var.query_insights_config.query_string_length >= 256 && var.query_insights_config.query_string_length <= 4500
    error_message = "Query string length must be between 256 and 4500 characters."
  }
}

# 🔥 Modern User Management Configuration
variable "user_config" {
  description = "Database user management configuration"
  type = object({
    # Default User
    default_user_name     = optional(string, "admin")
    default_user_password = optional(string) # If null, random generated

    # Additional Users
    additional_users = optional(map(object({
      password = string
      host     = optional(string, "%")
      password_policy = optional(object({
        allowed_failed_attempts      = optional(number, 5)
        password_expiration_duration = optional(string)
        enable_failed_attempts_check = optional(bool, true)
        enable_password_verification = optional(bool, true)
      }))
    })), {})
  })
  default   = {}
  sensitive = true
}

# 🔥 Modern High Availability Configuration
variable "high_availability_config" {
  description = "High availability and replication configuration"
  type = object({
    # Read Replicas
    read_replicas = optional(map(object({
      region          = string
      tier            = optional(string)
      failover_target = optional(bool, false)
      disk_autoresize = optional(bool, true)

      # Replica-specific settings
      replica_configuration = optional(object({
        failover_target           = optional(bool, false)
        master_heartbeat_period   = optional(number)
        password                  = optional(string)
        username                  = optional(string)
        dump_file_path            = optional(string)
        ca_certificate            = optional(string)
        client_certificate        = optional(string)
        client_key                = optional(string)
        connect_retry_interval    = optional(number)
        verify_server_certificate = optional(bool, false)
      }))
    })), {})
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
