# Load Balancer Module
# This module creates Google Cloud Load Balancers with the following components:
# - Global and Regional IP addresses (ip_addresses.tf)
# - SSL certificates and policies (ssl.tf)
# - Health checks (health_checks.tf)
# - Backend services with CDN and IAP support (backend_services.tf)
# - URL maps and target proxies (url_maps.tf)
# - Forwarding rules (forwarding_rules.tf)
# - Cloud Armor security policies (security.tf)

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# This file serves as the main entry point and documentation for the module.
# All resources are defined in their respective component files for better organization:
#
# Component Files:
# ├── ip_addresses.tf     - Global and regional IP address allocation
# ├── ssl.tf              - SSL certificates and security policies
# ├── health_checks.tf    - Health check configurations
# ├── backend_services.tf - Backend services with CDN and IAP
# ├── url_maps.tf         - URL mapping and target proxies
# ├── forwarding_rules.tf - Traffic forwarding configuration
# └── security.tf         - Cloud Armor security policies
#
# Configuration Files:
# ├── variables.tf        - Input variable definitions
# └── outputs.tf          - Output value definitions