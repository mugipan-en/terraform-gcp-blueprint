# 🔥 Cloud SQL Instance Configuration

# Cloud SQL Instance
resource "google_sql_database_instance" "main" {
  name             = local.instance_name
  database_version = local.final_database_config.database_version
  region           = var.region
  deletion_protection = local.final_database_config.deletion_protection

  settings {
    tier              = local.final_database_config.instance_type
    availability_type = local.final_database_config.availability_type
    disk_type         = local.final_database_config.disk_type
    disk_size         = local.final_database_config.disk_size_gb
    disk_autoresize   = local.final_database_config.disk_autoresize
    disk_autoresize_limit = local.final_database_config.disk_autoresize_limit

    # Backup configuration
    backup_configuration {
      enabled                        = local.final_backup_config.enabled
      start_time                     = local.final_backup_config.start_time
      location                       = local.final_backup_config.location
      point_in_time_recovery_enabled = local.final_backup_config.point_in_time_recovery_enabled
      transaction_log_retention_days = local.final_backup_config.transaction_log_retention_days
      binary_log_enabled            = local.final_backup_config.binary_log_enabled
      
      backup_retention_settings {
        retained_backups = local.final_backup_config.retained_backups
        retention_unit   = "COUNT"
      }
    }

    # Maintenance window
    maintenance_window {
      day          = local.final_maintenance_config.day
      hour         = local.final_maintenance_config.hour
      update_track = local.final_maintenance_config.update_track
    }

    # IP configuration
    ip_configuration {
      ipv4_enabled                                  = local.final_database_config.ipv4_enabled
      private_network                               = local.final_database_config.network
      require_ssl                                   = local.final_database_config.require_ssl
      allocated_ip_range                           = var.database_config.allocated_ip_range
      enable_private_path_for_google_cloud_services = true

      dynamic "authorized_networks" {
        for_each = local.final_database_config.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.value
        }
      }
    }

    # Database flags
    dynamic "database_flags" {
      for_each = local.final_database_config.database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    # Insights configuration
    insights_config {
      query_insights_enabled  = local.final_query_insights_config.enabled
      query_string_length     = local.final_query_insights_config.query_string_length
      record_application_tags = local.final_query_insights_config.record_application_tags
      record_client_address   = local.final_query_insights_config.record_client_address
      query_plans_per_minute  = local.final_query_insights_config.query_plans_per_minute
    }

    # User labels
    user_labels = local.common_labels

    # Advanced machine configuration
    advanced_machine_features {
      threads_per_core = 1
    }
  }

  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }
}

# Read replicas
resource "google_sql_database_instance" "read_replicas" {
  for_each = var.high_availability_config.read_replicas

  name               = "${local.instance_name}-${each.key}"
  master_instance_name = google_sql_database_instance.main.name
  region             = each.value.region
  database_version   = local.final_database_config.database_version
  deletion_protection = local.final_database_config.deletion_protection

  replica_configuration {
    failover_target = each.value.failover_target
  }

  settings {
    tier              = each.value.tier != null ? each.value.tier : local.final_database_config.instance_type
    availability_type = "ZONAL"  # Replicas are always zonal
    disk_autoresize   = each.value.disk_autoresize

    # IP configuration (inherits from master)
    ip_configuration {
      ipv4_enabled                                  = local.final_database_config.ipv4_enabled
      private_network                               = local.final_database_config.network
      require_ssl                                   = local.final_database_config.require_ssl
      enable_private_path_for_google_cloud_services = true
    }

    # User labels
    user_labels = merge(local.common_labels, {
      role = "read-replica"
      replica_of = google_sql_database_instance.main.name
    })
  }

  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }

  depends_on = [
    google_sql_database_instance.main
  ]
}