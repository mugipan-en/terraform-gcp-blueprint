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

variable "redis_instances" {
  description = "Redis instances to create"
  type = map(object({
    tier                    = string
    memory_size_gb          = number
    region                  = string
    location_id             = string
    alternative_location_id = string
    redis_version           = string
    display_name            = string
    reserved_ip_range       = string
    authorized_network      = string
    connect_mode            = string
    transit_encryption_mode = string
    auth_enabled            = bool
    redis_configs           = map(string)
    labels                  = map(string)

    maintenance_policy = object({
      description = string
      weekly_maintenance_window = list(object({
        day      = string
        duration = string
        start_time = object({
          hours   = number
          minutes = number
          seconds = number
          nanos   = number
        })
      }))
    })

    persistence_config = object({
      persistence_mode        = string
      rdb_snapshot_period     = string
      rdb_snapshot_start_time = string
    })
  }))
  default = {}
}

variable "memcached_instances" {
  description = "Memcached instances to create"
  type = map(object({
    region             = string
    authorized_network = string
    display_name       = string
    memcache_version   = string
    node_count         = number
    zones              = list(string)
    labels             = map(string)

    node_config = object({
      cpu_count      = number
      memory_size_mb = number
    })

    memcache_parameters = object({
      id     = string
      params = map(string)
    })

    maintenance_policy = object({
      description = string
      weekly_maintenance_window = list(object({
        day      = string
        duration = string
        start_time = object({
          hours   = number
          minutes = number
          seconds = number
          nanos   = number
        })
      }))
    })
  }))
  default = {}
}

variable "redis_backup_schedules" {
  description = "Redis backup schedules"
  type = map(object({
    source_instance_key = string
    schedule            = string
    retention_days      = number
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
