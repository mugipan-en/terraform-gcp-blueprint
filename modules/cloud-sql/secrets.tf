# 🔥 Secret Manager Integration

# Store database connection details in Secret Manager
resource "google_secret_manager_secret" "db_connection" {
  secret_id = "${local.instance_name}-connection"

  replication {
    automatic = true
  }

  labels = local.common_labels
}

# Database connection string
resource "google_secret_manager_secret_version" "db_connection" {
  secret      = google_secret_manager_secret.db_connection.id
  secret_data = jsonencode({
    instance_name     = google_sql_database_instance.main.name
    connection_name   = google_sql_database_instance.main.connection_name
    database_version  = local.final_database_config.database_version
    region           = var.region
    database_name    = local.final_database_config.name
    username         = var.user_config.default_user_name
    password         = var.user_config.default_user_password != null ? var.user_config.default_user_password : random_password.db_password[0].result
    
    # Connection details for different access methods
    public_ip_address  = google_sql_database_instance.main.public_ip_address
    private_ip_address = google_sql_database_instance.main.private_ip_address
    
    # Connection strings
    connection_string = "postgresql://${var.user_config.default_user_name}:${var.user_config.default_user_password != null ? var.user_config.default_user_password : random_password.db_password[0].result}@${google_sql_database_instance.main.private_ip_address}:5432/${local.final_database_config.name}"
    jdbc_url = "jdbc:postgresql://${google_sql_database_instance.main.private_ip_address}:5432/${local.final_database_config.name}"
  })

  depends_on = [
    google_sql_database_instance.main,
    google_sql_database.main,
    google_sql_user.default
  ]
}

# Store individual secrets
resource "google_secret_manager_secret" "db_password" {
  secret_id = "${local.instance_name}-password"

  replication {
    automatic = true
  }

  labels = merge(local.common_labels, {
    secret_type = "database-password"
  })
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.user_config.default_user_password != null ? var.user_config.default_user_password : random_password.db_password[0].result

  depends_on = [
    random_password.db_password,
    google_sql_user.default
  ]
}