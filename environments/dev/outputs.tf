output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region"
  value       = var.region
}

output "vpc_network_name" {
  description = "The name of the VPC network"
  value       = module.vpc.network_name
}

output "vpc_network_id" {
  description = "The ID of the VPC network"
  value       = module.vpc.network_id
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = module.vpc.subnet_name
}

output "gke_cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "The CA certificate of the GKE cluster"
  value       = module.gke.cluster_ca_certificate
  sensitive   = true
}

output "cloud_sql_instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = module.cloud_sql.instance_name
}

output "cloud_sql_connection_name" {
  description = "The connection name of the Cloud SQL instance"
  value       = module.cloud_sql.connection_name
}

output "cloud_sql_private_ip" {
  description = "The private IP of the Cloud SQL instance"
  value       = module.cloud_sql.private_ip
  sensitive   = true
}

output "storage_buckets" {
  description = "The names of the created storage buckets"
  value       = module.storage.bucket_names
}

output "service_account_emails" {
  description = "Email addresses of created service accounts"
  value       = module.security.service_account_emails
}

output "monitoring_notification_channels" {
  description = "Created monitoring notification channels"
  value       = module.monitoring.notification_channels
}