output "instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = google_sql_database_instance.main.name
}

output "instance_connection_name" {
  description = "Connection name of the Cloud SQL instance"
  value       = google_sql_database_instance.main.connection_name
}

output "instance_self_link" {
  description = "Self link of the Cloud SQL instance"
  value       = google_sql_database_instance.main.self_link
}

output "instance_server_ca_cert" {
  description = "Server CA certificate of the Cloud SQL instance"
  value       = google_sql_database_instance.main.server_ca_cert
  sensitive   = true
}

output "instance_ip_address" {
  description = "IP addresses of the Cloud SQL instance"
  value = {
    for ip in google_sql_database_instance.main.ip_address :
    ip.type => ip.ip_address
  }
  sensitive = true
}

output "private_ip_address" {
  description = "Private IP address of the Cloud SQL instance"
  value       = try(google_sql_database_instance.main.private_ip_address, null)
  sensitive   = true
}

output "public_ip_address" {
  description = "Public IP address of the Cloud SQL instance"
  value       = try(google_sql_database_instance.main.public_ip_address, null)
  sensitive   = true
}

output "instance_first_ip_address" {
  description = "First IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.main.first_ip_address
  sensitive   = true
}

output "database_version" {
  description = "Database version of the Cloud SQL instance"
  value       = google_sql_database_instance.main.database_version
}

output "instance_type" {
  description = "Instance type of the Cloud SQL instance"
  value       = google_sql_database_instance.main.settings[0].tier
}

output "default_database_name" {
  description = "Name of the default database"
  value       = google_sql_database.default.name
}

output "additional_databases" {
  description = "Names of additional databases"
  value       = values(google_sql_database.database)[*].name
}

output "default_user_name" {
  description = "Name of the default database user"
  value       = google_sql_user.default_user.name
}

output "default_user_password" {
  description = "Password of the default database user"
  value       = google_sql_user.default_user.password
  sensitive   = true
}

output "generated_password" {
  description = "Generated password for database access"
  value       = random_password.db_password.result
  sensitive   = true
}

output "password_secret_name" {
  description = "Name of the Secret Manager secret containing the database password"
  value       = google_secret_manager_secret.db_password.secret_id
}

output "password_secret_id" {
  description = "Full ID of the Secret Manager secret containing the database password"
  value       = google_secret_manager_secret.db_password.id
}

output "read_replica_instances" {
  description = "Information about read replica instances"
  value = {
    for k, v in google_sql_database_instance.read_replica : k => {
      name            = v.name
      connection_name = v.connection_name
      region          = v.region
      private_ip      = try(v.private_ip_address, null)
      public_ip       = try(v.public_ip_address, null)
    }
  }
  sensitive = true
}

# Connection information for applications
output "connection_info" {
  description = "Connection information for applications"
  value = {
    host              = google_sql_database_instance.main.private_ip_address
    port              = var.database_version == "POSTGRES_14" ? 5432 : (startswith(var.database_version, "MYSQL") ? 3306 : 1433)
    database          = google_sql_database.default.name
    username          = google_sql_user.default_user.name
    password_secret   = google_secret_manager_secret.db_password.secret_id
    connection_name   = google_sql_database_instance.main.connection_name
    ssl_required      = var.require_ssl
  }
  sensitive = true
}

# JDBC/Connection strings
output "jdbc_url" {
  description = "JDBC connection URL (PostgreSQL)"
  value = startswith(var.database_version, "POSTGRES") ? (
    "jdbc:postgresql://${google_sql_database_instance.main.private_ip_address}:5432/${google_sql_database.default.name}?sslmode=${var.require_ssl ? "require" : "disable"}"
  ) : null
  sensitive = true
}

output "mysql_url" {
  description = "MySQL connection URL"
  value = startswith(var.database_version, "MYSQL") ? (
    "mysql://${google_sql_user.default_user.name}:${google_sql_user.default_user.password}@${google_sql_database_instance.main.private_ip_address}:3306/${google_sql_database.default.name}?sslmode=${var.require_ssl ? "REQUIRED" : "DISABLED"}"
  ) : null
  sensitive = true
}

output "postgres_url" {
  description = "PostgreSQL connection URL"
  value = startswith(var.database_version, "POSTGRES") ? (
    "postgresql://${google_sql_user.default_user.name}:${google_sql_user.default_user.password}@${google_sql_database_instance.main.private_ip_address}:5432/${google_sql_database.default.name}?sslmode=${var.require_ssl ? "require" : "disable"}"
  ) : null
  sensitive = true
}