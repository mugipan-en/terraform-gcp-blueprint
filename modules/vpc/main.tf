# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  description             = "VPC network for ${var.name_prefix} environment"

  timeouts {
    create = "10m"
    delete = "10m"
  }
}

# Public Subnet
resource "google_compute_subnetwork" "public" {
  name          = "${var.name_prefix}-public-subnet"
  ip_cidr_range = var.subnet_cidrs.public
  region        = var.region
  network       = google_compute_network.vpc.id
  description   = "Public subnet for ${var.name_prefix} environment"

  # Enable private Google access for VMs without external IPs
  private_ip_google_access = true

  # Secondary ranges for GKE
  secondary_ip_range {
    range_name    = "${var.name_prefix}-pods"
    ip_cidr_range = var.subnet_cidrs.pods
  }

  secondary_ip_range {
    range_name    = "${var.name_prefix}-services"
    ip_cidr_range = var.subnet_cidrs.services
  }

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Private Subnet
resource "google_compute_subnetwork" "private" {
  name          = "${var.name_prefix}-private-subnet"
  ip_cidr_range = var.subnet_cidrs.private
  region        = var.region
  network       = google_compute_network.vpc.id
  description   = "Private subnet for ${var.name_prefix} environment"

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Cloud Router for NAT
resource "google_compute_router" "router" {
  name    = "${var.name_prefix}-router"
  region  = var.region
  network = google_compute_network.vpc.id

  bgp {
    asn = 64514
  }
}

# Cloud NAT for private subnet outbound connectivity
resource "google_compute_router_nat" "nat" {
  name                               = "${var.name_prefix}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall rule: Allow internal communication
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.name_prefix}-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [
    var.subnet_cidrs.public,
    var.subnet_cidrs.private,
    var.subnet_cidrs.pods,
    var.subnet_cidrs.services
  ]

  description = "Allow internal communication between subnets"
}

# Firewall rule: Allow SSH access
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.name_prefix}-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
  target_tags   = ["ssh-allowed"]
  description   = "Allow SSH access to instances with ssh-allowed tag"
}

# Firewall rule: Allow HTTP/HTTPS
resource "google_compute_firewall" "allow_http_https" {
  name    = "${var.name_prefix}-allow-http-https"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "https-server"]
  description   = "Allow HTTP and HTTPS traffic"
}

# Firewall rule: Allow health checks
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.name_prefix}-allow-health-checks"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "130.211.0.0/22", # Google Cloud health check ranges
    "35.191.0.0/16"
  ]

  target_tags = ["allow-health-checks"]
  description = "Allow Google Cloud health checks"
}

# Firewall rule: Deny all other inbound traffic
resource "google_compute_firewall" "deny_all" {
  name     = "${var.name_prefix}-deny-all"
  network  = google_compute_network.vpc.name
  priority = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  description   = "Deny all other inbound traffic (lowest priority)"
}

# Private Service Connection for Cloud SQL
resource "google_compute_global_address" "private_ip_range" {
  name          = "${var.name_prefix}-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = google_compute_network.vpc.id
  description   = "Private IP range for Google services"
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}
