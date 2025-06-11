# Redis instances
resource "google_redis_instance" "redis_instances" {
  for_each = var.redis_instances

  name           = "${var.name_prefix}-${each.key}"
  tier           = each.value.tier
  memory_size_gb = each.value.memory_size_gb
  region         = each.value.region
  location_id    = each.value.location_id
  alternative_location_id = each.value.alternative_location_id

  redis_version     = each.value.redis_version
  display_name      = each.value.display_name
  reserved_ip_range = each.value.reserved_ip_range
  
  redis_configs = each.value.redis_configs
  
  # Network configuration
  authorized_network         = each.value.authorized_network
  connect_mode              = each.value.connect_mode
  transit_encryption_mode   = each.value.transit_encryption_mode
  auth_enabled              = each.value.auth_enabled
  
  # Maintenance policy
  dynamic "maintenance_policy" {
    for_each = each.value.maintenance_policy != null ? [each.value.maintenance_policy] : []
    content {
      description = maintenance_policy.value.description
      
      dynamic "weekly_maintenance_window" {
        for_each = maintenance_policy.value.weekly_maintenance_window
        content {
          day = weekly_maintenance_window.value.day
          
          start_time {
            hours   = weekly_maintenance_window.value.start_time.hours
            minutes = weekly_maintenance_window.value.start_time.minutes
            seconds = weekly_maintenance_window.value.start_time.seconds
            nanos   = weekly_maintenance_window.value.start_time.nanos
          }
          
          duration = weekly_maintenance_window.value.duration
        }
      }
    }
  }

  # Persistence configuration
  dynamic "persistence_config" {
    for_each = each.value.persistence_config != null ? [each.value.persistence_config] : []
    content {
      persistence_mode    = persistence_config.value.persistence_mode
      rdb_snapshot_period = persistence_config.value.rdb_snapshot_period
      rdb_snapshot_start_time = persistence_config.value.rdb_snapshot_start_time
    }
  }

  labels = merge(var.tags, each.value.labels)

  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }
}

# Memcached instances
resource "google_memcache_instance" "memcached_instances" {
  for_each = var.memcached_instances

  name           = "${var.name_prefix}-${each.key}"
  region         = each.value.region
  authorized_network = each.value.authorized_network
  display_name   = each.value.display_name
  memcache_version = each.value.memcache_version

  node_config {
    cpu_count      = each.value.node_config.cpu_count
    memory_size_mb = each.value.node_config.memory_size_mb
  }

  node_count = each.value.node_count
  zones      = each.value.zones

  memcache_parameters {
    id    = each.value.memcache_parameters.id
    params = each.value.memcache_parameters.params
  }

  # Maintenance policy
  dynamic "maintenance_policy" {
    for_each = each.value.maintenance_policy != null ? [each.value.maintenance_policy] : []
    content {
      description = maintenance_policy.value.description
      
      dynamic "weekly_maintenance_window" {
        for_each = maintenance_policy.value.weekly_maintenance_window
        content {
          day = weekly_maintenance_window.value.day
          duration = weekly_maintenance_window.value.duration
          
          start_time {
            hours   = weekly_maintenance_window.value.start_time.hours
            minutes = weekly_maintenance_window.value.start_time.minutes
            seconds = weekly_maintenance_window.value.start_time.seconds
            nanos   = weekly_maintenance_window.value.start_time.nanos
          }
        }
      }
    }
  }

  labels = merge(var.tags, each.value.labels)

  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }
}

# Redis backup schedules
resource "google_redis_instance" "redis_backup_schedules" {
  for_each = var.redis_backup_schedules

  name     = "${var.name_prefix}-${each.key}-backup"
  tier     = "STANDARD_HA"
  memory_size_gb = var.redis_instances[each.value.source_instance_key].memory_size_gb
  region   = var.redis_instances[each.value.source_instance_key].region

  # This creates a backup instance that can be used for point-in-time recovery
  # In a real implementation, you'd use Cloud Scheduler + Cloud Functions
  # to create actual backup schedules
  
  labels = merge(var.tags, {
    purpose = "backup"
    source  = each.value.source_instance_key
  })
}