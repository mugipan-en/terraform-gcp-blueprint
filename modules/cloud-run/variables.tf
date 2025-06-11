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

variable "services" {
  description = "Cloud Run services to create"
  type = map(object({
    location                  = string
    image                    = string
    min_scale                = number
    max_scale                = number
    container_concurrency    = number
    timeout_seconds          = number
    cpu_limit                = string
    memory_limit             = string
    cpu_request              = string
    memory_request           = string
    service_account_email    = string
    execution_environment    = string
    cpu_throttling           = bool
    autogenerate_revision_name = bool
    
    env_vars = map(string)
    env_vars_from_secrets = list(object({
      name        = string
      secret_name = string
      key         = string
    }))
    
    ports = list(object({
      name           = string
      protocol       = string
      container_port = number
    }))
    
    volume_mounts = list(object({
      name       = string
      mount_path = string
    }))
    
    volumes = list(object({
      name = string
      secret = object({
        secret_name  = string
        default_mode = number
        items = list(object({
          key  = string
          path = string
          mode = number
        }))
      })
      config_map = object({
        name         = string
        default_mode = number
        items = list(object({
          key  = string
          path = string
          mode = number
        }))
      })
    }))
    
    startup_probe = object({
      initial_delay_seconds = number
      timeout_seconds      = number
      period_seconds       = number
      failure_threshold    = number
      http_get = object({
        path = string
        port = number
        http_headers = list(object({
          name  = string
          value = string
        }))
      })
    })
    
    liveness_probe = object({
      initial_delay_seconds = number
      timeout_seconds      = number
      period_seconds       = number
      failure_threshold    = number
      http_get = object({
        path = string
        port = number
        http_headers = list(object({
          name  = string
          value = string
        }))
      })
    })
    
    traffic_allocation = list(object({
      percent         = number
      latest_revision = bool
      revision_name   = string
      tag             = string
    }))
    
    annotations = map(string)
    labels      = map(string)
  }))
  default = {}
}

variable "iam_bindings" {
  description = "IAM bindings for Cloud Run services"
  type = map(object({
    service_key = string
    role        = string
    members     = list(string)
  }))
  default = {}
}

variable "domain_mappings" {
  description = "Domain mappings for Cloud Run services"
  type = map(object({
    service_key = string
    domain_name = string
    labels      = map(string)
    annotations = map(string)
  }))
  default = {}
}

variable "vpc_connectors" {
  description = "VPC connectors for Cloud Run"
  type = map(object({
    ip_cidr_range  = string
    network        = string
    region         = string
    subnet_name    = string
    min_throughput = number
    max_throughput = number
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}