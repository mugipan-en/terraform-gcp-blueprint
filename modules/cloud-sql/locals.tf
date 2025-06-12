# 🔥 Smart Environment Configuration and Local Values
locals {
  # Environment-based defaults
  environment_defaults = {
    dev = {
      instance_type       = "db-f1-micro"
      availability_type   = "ZONAL"
      disk_type          = "PD_HDD"
      disk_size_gb       = 20
      backup_enabled     = false
      deletion_protection = false
      require_ssl        = false
      point_in_time_recovery_enabled = false
      query_insights_enabled = false
    }
    staging = {
      instance_type       = "db-g1-small"
      availability_type   = "ZONAL"
      disk_type          = "PD_SSD"
      disk_size_gb       = 50
      backup_enabled     = true
      deletion_protection = true
      require_ssl        = true
      point_in_time_recovery_enabled = true
      query_insights_enabled = true
    }
    production = {
      instance_type       = "db-n1-standard-2"
      availability_type   = "REGIONAL"
      disk_type          = "PD_SSD"
      disk_size_gb       = 100
      backup_enabled     = true
      deletion_protection = true
      require_ssl        = true
      point_in_time_recovery_enabled = true
      query_insights_enabled = true
    }
  }
  
  # Merge environment defaults with user configuration
  env_config = local.environment_defaults[var.environment]
  
  # Final database configuration
  final_database_config = merge(local.env_config, {
    name             = var.database_config.name
    database_version = var.database_config.database_version
    network          = var.database_config.network
    ipv4_enabled     = var.database_config.ipv4_enabled
    authorized_networks = var.database_config.authorized_networks
    charset          = var.database_config.charset
    collation        = var.database_config.collation
    additional_databases = var.database_config.additional_databases
    database_flags   = var.database_config.database_flags
  })
  
  # Backup configuration merged with environment defaults
  final_backup_config = merge({
    enabled                        = local.env_config.backup_enabled
    start_time                     = var.backup_config.start_time
    location                       = var.backup_config.location
    point_in_time_recovery_enabled = local.env_config.point_in_time_recovery_enabled
    transaction_log_retention_days = var.backup_config.transaction_log_retention_days
    retained_backups              = var.backup_config.retained_backups
    binary_log_enabled            = var.backup_config.binary_log_enabled
  }, var.backup_config)
  
  # Maintenance configuration
  final_maintenance_config = merge({
    day          = var.maintenance_config.day
    hour         = var.maintenance_config.hour
    update_track = var.maintenance_config.update_track
  }, var.maintenance_config)
  
  # Query insights configuration
  final_query_insights_config = merge({
    enabled                = local.env_config.query_insights_enabled
    query_string_length   = var.query_insights_config.query_string_length
    record_application_tags = var.query_insights_config.record_application_tags
    record_client_address  = var.query_insights_config.record_client_address
    query_plans_per_minute = var.query_insights_config.query_plans_per_minute
  }, var.query_insights_config)
  
  # Instance name
  instance_name = "${var.name_prefix}-${local.final_database_config.name}"
  
  # Common labels
  common_labels = merge(var.tags, {
    environment = var.environment
    managed_by  = "terraform"
    service     = "cloud-sql"
  })
}