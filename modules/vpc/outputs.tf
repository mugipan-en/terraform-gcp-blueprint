output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "network_self_link" {
  description = "Self link of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "public_subnet_name" {
  description = "Name of the public subnet"
  value       = google_compute_subnetwork.public.name
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = google_compute_subnetwork.public.id
}

output "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  value       = google_compute_subnetwork.public.ip_cidr_range
}

output "private_subnet_name" {
  description = "Name of the private subnet"
  value       = google_compute_subnetwork.private.name
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = google_compute_subnetwork.private.id
}

output "private_subnet_cidr" {
  description = "CIDR block of the private subnet"
  value       = google_compute_subnetwork.private.ip_cidr_range
}

output "pods_range_name" {
  description = "Name of the pods IP range for GKE"
  value       = google_compute_subnetwork.public.secondary_ip_range[0].range_name
}

output "services_range_name" {
  description = "Name of the services IP range for GKE"
  value       = google_compute_subnetwork.public.secondary_ip_range[1].range_name
}

output "router_name" {
  description = "Name of the Cloud Router"
  value       = google_compute_router.router.name
}

output "nat_name" {
  description = "Name of the Cloud NAT"
  value       = google_compute_router_nat.nat.name
}

output "private_service_connection_name" {
  description = "Name of the private service connection"
  value       = google_service_networking_connection.private_vpc_connection.network
}