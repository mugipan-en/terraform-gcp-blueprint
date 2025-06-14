variable "project_id" {
  description = "The project ID to deploy resources into"
  type        = string
}

variable "create_application" {
  description = "Whether to create the App Engine application"
  type        = bool
  default     = true
}

variable "location_id" {
  description = "The location to serve the app from"
  type        = string
  default     = "us-central"
}

variable "iap_config" {
  description = "Identity-Aware Proxy configuration"
  type = object({
    oauth2_client_id     = string
    oauth2_client_secret = string
  })
  default = null
}

variable "feature_settings" {
  description = "Feature settings for the App Engine application"
  type = object({
    split_health_checks = optional(bool, true)
  })
  default = null
}

# Standard App Engine Services
variable "standard_services" {
  description = "Standard App Engine services configuration"
  type = map(object({
    service_name = string
    version_id   = string
    runtime      = string
    threadsafe   = optional(bool, true)

    deployment = optional(object({
      zip = optional(object({
        source_url  = string
        files_count = optional(number)
      }))
      files = optional(map(object({
        source_url = string
        sha1_sum   = optional(string)
      })))
    }))

    entrypoint = optional(object({
      shell = string
    }))

    env_variables    = optional(map(string), {})
    instance_class   = optional(string, "F1")
    inbound_services = optional(list(string), [])

    automatic_scaling = optional(object({
      max_concurrent_requests = optional(number, 10)
      max_idle_instances      = optional(number, 1)
      max_pending_latency     = optional(string, "1s")
      min_idle_instances      = optional(number, 0)
      min_pending_latency     = optional(string, "0.01s")

      standard_scheduler_settings = optional(object({
        target_cpu_utilization        = optional(number, 0.6)
        target_throughput_utilization = optional(number, 0.6)
        min_instances                 = optional(number, 0)
        max_instances                 = optional(number, 10)
      }))
    }))

    basic_scaling = optional(object({
      idle_timeout  = optional(string, "5m")
      max_instances = number
    }))

    manual_scaling = optional(object({
      instances = number
    }))

    vpc_access_connector = optional(object({
      name = string
    }))

    handlers = optional(list(object({
      url_regex                   = string
      security_level              = optional(string, "SECURE_DEFAULT")
      login                       = optional(string, "LOGIN_OPTIONAL")
      auth_fail_action            = optional(string, "AUTH_FAIL_ACTION_REDIRECT")
      redirect_http_response_code = optional(string, "REDIRECT_HTTP_RESPONSE_CODE_301")

      script = optional(object({
        script_path = string
      }))

      static_files = optional(object({
        path                  = optional(string)
        upload_path_regex     = optional(string)
        http_headers          = optional(map(string))
        mime_type             = optional(string)
        expiration            = optional(string)
        require_matching_file = optional(bool, false)
      }))
    })))

    libraries = optional(list(object({
      name    = string
      version = string
    })))

    noop_on_destroy           = optional(bool, false)
    delete_service_on_destroy = optional(bool, false)
  }))
  default = {}
}

# Flexible App Engine Services
variable "flexible_services" {
  description = "Flexible App Engine services configuration"
  type = map(object({
    service_name = string
    version_id   = string
    runtime      = string

    deployment = optional(object({
      container = optional(object({
        image = string
      }))
      zip = optional(object({
        source_url  = string
        files_count = optional(number)
      }))
      files = optional(map(object({
        source_url = string
        sha1_sum   = optional(string)
      })))
    }))

    entrypoint = optional(object({
      shell = string
    }))

    runtime_config = optional(object({
      operating_system = optional(string)
      runtime_version  = optional(string)
    }))

    env_variables    = optional(map(string), {})
    beta_settings    = optional(map(string), {})
    serving_status   = optional(string, "SERVING")
    inbound_services = optional(list(string), [])

    automatic_scaling = optional(object({
      cool_down_period        = optional(string, "120s")
      max_concurrent_requests = optional(number, 10)
      max_idle_instances      = optional(number, 1)
      max_pending_latency     = optional(string, "1s")
      max_total_instances     = optional(number, 20)
      min_idle_instances      = optional(number, 0)
      min_pending_latency     = optional(string, "0.01s")
      min_total_instances     = optional(number, 1)

      cpu_utilization = optional(object({
        aggregation_window_length = optional(string, "60s")
        target_utilization        = number
      }))

      disk_utilization = optional(object({
        target_read_bytes_per_second  = optional(number)
        target_read_ops_per_second    = optional(number)
        target_write_bytes_per_second = optional(number)
        target_write_ops_per_second   = optional(number)
      }))

      network_utilization = optional(object({
        target_received_bytes_per_second   = optional(number)
        target_received_packets_per_second = optional(number)
        target_sent_bytes_per_second       = optional(number)
        target_sent_packets_per_second     = optional(number)
      }))

      request_utilization = optional(object({
        target_concurrent_requests      = optional(number)
        target_request_count_per_second = optional(number)
      }))
    }))

    manual_scaling = optional(object({
      instances = number
    }))

    vpc_access_connector = optional(object({
      name = string
    }))

    resources = optional(object({
      cpu       = optional(number, 1)
      memory_gb = optional(number, 0.6)
      disk_gb   = optional(number, 10)

      volumes = optional(list(object({
        name        = string
        volume_type = string
        size_gb     = number
      })))
    }))

    network = optional(object({
      name             = string
      subnetwork       = optional(string)
      session_affinity = optional(bool, false)
      instance_tag     = optional(string)
      forwarded_ports  = optional(list(string))
    }))

    liveness_check = optional(object({
      check_interval    = optional(string, "30s")
      failure_threshold = optional(number, 4)
      host              = optional(string)
      initial_delay     = optional(string, "300s")
      path              = optional(string, "/")
      success_threshold = optional(number, 1)
      timeout           = optional(string, "4s")
    }))

    readiness_check = optional(object({
      app_start_timeout = optional(string, "300s")
      check_interval    = optional(string, "5s")
      failure_threshold = optional(number, 2)
      host              = optional(string)
      path              = optional(string, "/")
      success_threshold = optional(number, 1)
      timeout           = optional(string, "4s")
    }))

    noop_on_destroy           = optional(bool, false)
    delete_service_on_destroy = optional(bool, false)
  }))
  default = {}
}

# Traffic Splitting
variable "traffic_splits" {
  description = "Traffic splitting configurations"
  type = map(object({
    service         = string
    migrate_traffic = optional(bool, false)

    split = object({
      shard_by    = optional(string, "IP")
      allocations = map(string)
    })
  }))
  default = {}
}

# Domain Mappings
variable "domain_mappings" {
  description = "Domain mapping configurations"
  type = map(object({
    domain_name       = string
    override_strategy = optional(string, "STRICT")

    ssl_settings = optional(object({
      certificate_id                 = optional(string)
      ssl_management_type            = optional(string, "AUTOMATIC")
      pending_managed_certificate_id = optional(string)
    }))
  }))
  default = {}
}

# Managed SSL Certificates
variable "managed_certificates" {
  description = "Managed SSL certificate configurations"
  type = map(object({
    display_name = string
    domains      = list(string)
  }))
  default = {}
}

# Firewall Rules
variable "firewall_rules" {
  description = "App Engine firewall rule configurations"
  type = map(object({
    priority     = number
    action       = string # "ALLOW" or "DENY"
    source_range = string
    description  = optional(string)
  }))
  default = {}
}
