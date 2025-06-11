# Random password for database user
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Cloud SQL Instance
resource "google_sql_database_instance" "main" {
  name             = "${var.name_prefix}-${var.database_name}"
  database_version = var.database_version
  region           = var.region

  settings {
    tier                        = var.instance_type
    availability_type           = var.availability_type
    disk_type                   = var.disk_type
    disk_size                   = var.disk_size_gb
    disk_autoresize            = var.disk_autoresize
    disk_autoresize_limit      = var.disk_autoresize_limit

    # Backup configuration
    backup_configuration {
      enabled                        = var.backup_enabled
      start_time                     = var.backup_start_time
      location                       = var.backup_location
      point_in_time_recovery_enabled = var.point_in_time_recovery_enabled
      transaction_log_retention_days = var.transaction_log_retention_days
      backup_retention_settings {
        retained_backups = var.retained_backups
        retention_unit   = "COUNT"
      }
    }

    # Maintenance window
    maintenance_window {
      day          = var.maintenance_window_day
      hour         = var.maintenance_window_hour
      update_track = var.maintenance_window_update_track
    }

    # IP configuration
    ip_configuration {
      ipv4_enabled                                  = var.ipv4_enabled
      private_network                               = var.network
      enable_private_path_for_google_cloud_services = true
      require_ssl                                   = var.require_ssl

      # Authorized networks (if ipv4_enabled)
      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.value
        }
      }
    }

    # Database flags
    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    # Insights configuration
    insights_config {
      query_insights_enabled  = var.query_insights_enabled
      query_string_length     = var.query_string_length
      record_application_tags = var.record_application_tags
      record_client_address   = var.record_client_address
    }

    # User labels
    user_labels = var.tags
  }

  # High availability replica (if enabled)
  dynamic "replica_configuration" {
    for_each = var.availability_type == "REGIONAL" ? [1] : []
    content {
      failover_target = false
    }
  }

  deletion_protection = var.deletion_protection

  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }

  depends_on = [var.network]
}

# Additional read replicas
resource "google_sql_database_instance" "read_replica" {
  for_each = var.read_replicas

  name                 = "${var.name_prefix}-${var.database_name}-replica-${each.key}"
  master_instance_name = google_sql_database_instance.main.name
  region               = each.value.region
  database_version     = google_sql_database_instance.main.database_version

  replica_configuration {
    failover_target = each.value.failover_target
  }

  settings {
    tier                  = each.value.tier
    availability_type     = "ZONAL"
    disk_autoresize      = var.disk_autoresize
    disk_autoresize_limit = var.disk_autoresize_limit

    ip_configuration {
      ipv4_enabled    = var.ipv4_enabled
      private_network = var.network
      require_ssl     = var.require_ssl

      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.value
        }
      }
    }

    # Database flags
    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    user_labels = merge(var.tags, {
      replica_of = google_sql_database_instance.main.name
    })
  }

  deletion_protection = var.deletion_protection

  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }
}

# Database
resource "google_sql_database" "database" {
  for_each = toset(var.additional_databases)

  name     = each.value
  instance = google_sql_database_instance.main.name
  charset  = var.charset
  collation = var.collation
}

# Default database
resource "google_sql_database" "default" {
  name     = var.database_name
  instance = google_sql_database_instance.main.name
  charset  = var.charset
  collation = var.collation
}

# Database users
resource "google_sql_user" "users" {
  for_each = var.database_users

  name     = each.key
  instance = google_sql_database_instance.main.name
  password = each.value.password != null ? each.value.password : random_password.db_password.result
  host     = each.value.host

  # For PostgreSQL, we can set additional attributes
  dynamic "password_policy" {
    for_each = each.value.password_policy != null ? [each.value.password_policy] : []
    content {
      allowed_failed_attempts      = password_policy.value.allowed_failed_attempts
      password_expiration_duration = password_policy.value.password_expiration_duration
      enable_failed_attempts_check = password_policy.value.enable_failed_attempts_check
      enable_password_verification = password_policy.value.enable_password_verification
    }
  }
}

# Default admin user
resource "google_sql_user" "default_user" {
  name     = var.default_user_name
  instance = google_sql_database_instance.main.name
  password = var.default_user_password != null ? var.default_user_password : random_password.db_password.result
}

# Store the password in Secret Manager
resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.name_prefix}-db-password"
  
  replication {
    automatic = true
  }

  labels = var.tags
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}