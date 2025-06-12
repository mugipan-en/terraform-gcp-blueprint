# 🔥 Database and User Management

# Random password for database user
resource "random_password" "db_password" {
  count   = var.user_config.default_user_password == null ? 1 : 0
  length  = 32
  special = true
}

# Main database
resource "google_sql_database" "main" {
  name     = local.final_database_config.name
  instance = google_sql_database_instance.main.name
  charset  = local.final_database_config.charset
  collation = local.final_database_config.collation

  depends_on = [
    google_sql_database_instance.main
  ]
}

# Additional databases
resource "google_sql_database" "additional" {
  for_each = toset(local.final_database_config.additional_databases)

  name     = each.value
  instance = google_sql_database_instance.main.name
  charset  = local.final_database_config.charset
  collation = local.final_database_config.collation

  depends_on = [
    google_sql_database_instance.main
  ]
}

# Default database user
resource "google_sql_user" "default" {
  name     = var.user_config.default_user_name
  instance = google_sql_database_instance.main.name
  password = var.user_config.default_user_password != null ? var.user_config.default_user_password : random_password.db_password[0].result

  depends_on = [
    google_sql_database_instance.main
  ]
}

# Additional database users
resource "google_sql_user" "additional" {
  for_each = var.user_config.additional_users

  name     = each.key
  instance = google_sql_database_instance.main.name
  host     = each.value.host
  password = each.value.password

  # Password policy (PostgreSQL only)
  dynamic "password_policy" {
    for_each = each.value.password_policy != null ? [each.value.password_policy] : []
    content {
      allowed_failed_attempts      = password_policy.value.allowed_failed_attempts
      password_expiration_duration = password_policy.value.password_expiration_duration
      enable_failed_attempts_check = password_policy.value.enable_failed_attempts_check
      enable_password_verification = password_policy.value.enable_password_verification
    }
  }

  depends_on = [
    google_sql_database_instance.main
  ]
}