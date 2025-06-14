# Basic Configuration
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

# 🔥 Modern VPC Configuration
variable "vpc_config" {
  description = "Comprehensive VPC network configuration"
  type = object({
    name         = optional(string, "main-vpc")
    routing_mode = optional(string, "REGIONAL")
    description  = optional(string)

    # Delete default internet gateway routes
    delete_default_routes_on_create = optional(bool, false)

    # Enable BGP routing
    enable_ula_internal_ipv6 = optional(bool, false)

    # Internal IPv6 range
    internal_ipv6_range = optional(string)
  })
  default = {}

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.vpc_config.routing_mode)
    error_message = "Routing mode must be either REGIONAL or GLOBAL."
  }
}

# 🔥 Modern Subnet Configuration
variable "subnet_config" {
  description = "Subnet configuration with CIDR blocks and features"
  type = object({
    # Primary subnets
    public_cidr  = optional(string, "10.0.1.0/24")
    private_cidr = optional(string, "10.0.2.0/24")

    # Secondary ranges for GKE
    pods_cidr     = optional(string, "10.1.0.0/16")
    services_cidr = optional(string, "10.2.0.0/16")

    # Subnet features
    enable_private_google_access = optional(bool, true)
    enable_flow_logs             = optional(bool, true)

    # Flow logs configuration
    flow_logs_config = optional(object({
      aggregation_interval = optional(string, "INTERVAL_5_SEC")
      flow_sampling        = optional(number, 0.5)
      metadata             = optional(string, "INCLUDE_ALL_METADATA")
      metadata_fields      = optional(list(string))
      filter_expr          = optional(string)
    }), {})

    # Additional secondary ranges
    secondary_ranges = optional(map(object({
      range_name    = string
      ip_cidr_range = string
    })), {})
  })
  default = {}

  validation {
    condition = alltrue([
      can(cidrhost(var.subnet_config.public_cidr, 0)),
      can(cidrhost(var.subnet_config.private_cidr, 0)),
      can(cidrhost(var.subnet_config.pods_cidr, 0)),
      can(cidrhost(var.subnet_config.services_cidr, 0))
    ])
    error_message = "All subnet CIDRs must be valid CIDR blocks."
  }

  validation {
    condition     = var.subnet_config.flow_logs_config.flow_sampling >= 0.0 && var.subnet_config.flow_logs_config.flow_sampling <= 1.0
    error_message = "Flow logs sampling rate must be between 0.0 and 1.0."
  }
}

# 🔥 Modern Firewall Configuration
variable "firewall_config" {
  description = "Firewall rules configuration"
  type = object({
    # SSH access
    ssh_source_ranges = optional(list(string), ["0.0.0.0/0"])

    # Enable default rules
    enable_ssh_from_anywhere = optional(bool, false)
    enable_rdp_from_anywhere = optional(bool, false)
    enable_icmp              = optional(bool, true)

    # Custom firewall rules
    custom_rules = optional(map(object({
      direction   = optional(string, "INGRESS")
      priority    = optional(number, 1000)
      description = optional(string)
      ranges      = optional(list(string), [])
      source_tags = optional(list(string), [])
      target_tags = optional(list(string), [])

      allow = optional(list(object({
        protocol = string
        ports    = optional(list(string), [])
      })), [])

      deny = optional(list(object({
        protocol = string
        ports    = optional(list(string), [])
      })), [])

      log_config = optional(object({
        metadata = string
      }))
    })), {})
  })
  default = {}

  validation {
    condition = alltrue([
      for cidr in var.firewall_config.ssh_source_ranges :
      can(cidrhost(cidr, 0))
    ])
    error_message = "All SSH source ranges must be valid CIDR blocks."
  }
}

# 🔥 Modern NAT Configuration
variable "nat_config" {
  description = "Cloud NAT configuration"
  type = object({
    enable = optional(bool, true)

    # NAT IP allocation
    nat_ip_allocate_option = optional(string, "AUTO_ONLY")

    # Source subnetwork IP ranges to NAT
    source_subnetwork_ip_ranges_to_nat = optional(string, "ALL_SUBNETWORKS_ALL_IP_RANGES")

    # Logging
    enable_logging = optional(bool, true)
    log_config = optional(object({
      filter = optional(string, "ERRORS_ONLY")
    }), {})

    # UDP idle timeout
    udp_idle_timeout_sec             = optional(number, 30)
    tcp_established_idle_timeout_sec = optional(number, 1200)
    tcp_transitory_idle_timeout_sec  = optional(number, 30)
    icmp_idle_timeout_sec            = optional(number, 30)
  })
  default = {}

  validation {
    condition     = contains(["AUTO_ONLY", "MANUAL_ONLY"], var.nat_config.nat_ip_allocate_option)
    error_message = "NAT IP allocate option must be either AUTO_ONLY or MANUAL_ONLY."
  }

  validation {
    condition     = contains(["ALL_SUBNETWORKS_ALL_IP_RANGES", "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES", "LIST_OF_SUBNETWORKS"], var.nat_config.source_subnetwork_ip_ranges_to_nat)
    error_message = "Invalid source subnetwork IP ranges to NAT option."
  }
}

# Environment-aware Defaults
variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

# Resource Tagging
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
