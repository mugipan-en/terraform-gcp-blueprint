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

# 🔥 Modern Cloud Run Services Configuration
variable "services" {
  description = "Comprehensive Cloud Run services configuration"
  type = map(object({
    # Basic Service Configuration
    location = optional(string)
    image    = string
    
    # Scaling Configuration
    min_scale             = optional(number, 0)
    max_scale             = optional(number, 100)
    container_concurrency = optional(number, 80)
    
    # Resource Configuration
    cpu_limit      = optional(string, "1000m")
    memory_limit   = optional(string, "512Mi")
    cpu_request    = optional(string, "1000m")
    memory_request = optional(string, "512Mi")
    
    # Runtime Configuration
    timeout_seconds           = optional(number, 300)
    execution_environment     = optional(string, "EXECUTION_ENVIRONMENT_GEN2")
    cpu_throttling           = optional(bool, true)
    autogenerate_revision_name = optional(bool, true)
    
    # Service Account
    service_account_email = optional(string)
    
    # Environment Variables
    env_vars = optional(map(string), {})
    env_vars_from_secrets = optional(list(object({
      name        = string
      secret_name = string
      key         = string
    })), [])
    
    # Port Configuration
    ports = optional(list(object({
      name           = optional(string, "http1")
      protocol       = optional(string, "TCP")
      container_port = optional(number, 8080)
    })), [{
      name           = "http1"
      protocol       = "TCP"
      container_port = 8080
    }])
    
    # Volume Configuration
    volume_mounts = optional(list(object({
      name       = string
      mount_path = string
    })), [])
    
    volumes = optional(list(object({
      name = string
      secret = optional(object({
        secret_name  = string
        default_mode = optional(number, 420)
        items = optional(list(object({
          key  = string
          path = string
          mode = optional(number, 420)
        })), [])
      }))
      config_map = optional(object({
        name         = string
        default_mode = optional(number, 420)
        items = optional(list(object({
          key  = string
          path = string
          mode = optional(number, 420)
        })), [])
      }))
    })), [])
    
    # Health Checks
    startup_probe = optional(object({
      initial_delay_seconds = optional(number, 0)
      timeout_seconds      = optional(number, 240)
      period_seconds       = optional(number, 240)
      failure_threshold    = optional(number, 1)
      http_get = optional(object({
        path = optional(string, "/")
        port = optional(number, 8080)
        http_headers = optional(list(object({
          name  = string
          value = string
        })), [])
      }))
    }))
    
    liveness_probe = optional(object({
      initial_delay_seconds = optional(number, 0)
      timeout_seconds      = optional(number, 240)
      period_seconds       = optional(number, 240)
      failure_threshold    = optional(number, 3)
      http_get = optional(object({
        path = optional(string, "/")
        port = optional(number, 8080)
        http_headers = optional(list(object({
          name  = string
          value = string
        })), [])
      }))
    }))
    
    # Traffic Management
    traffic_allocation = optional(list(object({
      percent         = number
      latest_revision = optional(bool, true)
      revision_name   = optional(string)
      tag             = optional(string)
    })), [{
      percent = 100
      latest_revision = true
    }])
    
    # Metadata
    annotations = optional(map(string), {})
    labels      = optional(map(string), {})
  }))
  default = {}
  
  validation {
    condition = alltrue([
      for name, service in var.services :
      service.min_scale >= 0 && service.min_scale <= service.max_scale
    ])
    error_message = "min_scale must be >= 0 and <= max_scale for all services."
  }
  
  validation {
    condition = alltrue([
      for name, service in var.services :
      service.container_concurrency >= 1 && service.container_concurrency <= 1000
    ])
    error_message = "container_concurrency must be between 1 and 1000 for all services."
  }
}

# 🔥 Modern IAM Configuration
variable "iam_config" {
  description = "IAM bindings for Cloud Run services"
  type = object({
    # Default IAM bindings for all services
    default_bindings = optional(map(object({
      role    = string
      members = list(string)
    })), {})
    
    # Service-specific IAM bindings
    service_bindings = optional(map(object({
      service_key = string
      role        = string
      members     = list(string)
    })), {})
    
    # Public access settings
    allow_unauthenticated = optional(bool, false)
  })
  default = {}
}

# 🔥 Modern Domain Configuration
variable "domain_config" {
  description = "Domain mappings and custom domains"
  type = object({
    mappings = optional(map(object({
      service_key = string
      domain_name = string
      
      # SSL settings
      force_override = optional(bool, false)
      
      # Certificate configuration
      certificate_mode = optional(string, "AUTOMATIC")
      
      # Metadata
      labels      = optional(map(string), {})
      annotations = optional(map(string), {})
    })), {})
  })
  default = {}
  
  validation {
    condition = alltrue([
      for name, mapping in var.domain_config.mappings :
      contains(["AUTOMATIC", "MANUAL"], mapping.certificate_mode)
    ])
    error_message = "Certificate mode must be either AUTOMATIC or MANUAL."
  }
}

# 🔥 Modern VPC Connector Configuration
variable "vpc_connector_config" {
  description = "VPC connectors for private network access"
  type = object({
    connectors = optional(map(object({
      # Network Configuration
      ip_cidr_range = string
      network      = string
      subnet_name  = optional(string)
      
      # Throughput Configuration
      min_throughput = optional(number, 200)
      max_throughput = optional(number, 300)
      
      # Instance Configuration
      min_instances = optional(number, 2)
      max_instances = optional(number, 10)
      
      # Machine type
      machine_type = optional(string, "e2-micro")
      
      # Labels
      labels = optional(map(string), {})
    })), {})
  })
  default = {}
  
  validation {
    condition = alltrue([
      for name, connector in var.vpc_connector_config.connectors :
      can(cidrhost(connector.ip_cidr_range, 0))
    ])
    error_message = "All VPC connector IP CIDR ranges must be valid CIDR blocks."
  }
  
  validation {
    condition = alltrue([
      for name, connector in var.vpc_connector_config.connectors :
      connector.min_throughput >= 200 && connector.min_throughput <= connector.max_throughput
    ])
    error_message = "min_throughput must be >= 200 and <= max_throughput."
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