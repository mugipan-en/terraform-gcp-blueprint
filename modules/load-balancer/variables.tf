variable "project_id" {
  description = "The project ID to deploy resources into"
  type        = string
}

variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Global Load Balancers
variable "global_load_balancers" {
  description = "Global load balancer configurations"
  type = map(object({
    ip_version              = optional(string, "IPV4")
    default_backend_service = string
    ssl_certificates        = optional(list(string), [])
    ssl_policy_key          = optional(string)
    security_policy_key     = optional(string)

    host_rules = optional(list(object({
      hosts        = list(string)
      path_matcher = string
    })), [])

    path_matchers = optional(list(object({
      name            = string
      default_service = string
      path_rules = list(object({
        paths   = list(string)
        service = string
      }))
    })), [])

    url_map_tests = optional(list(object({
      service     = string
      host        = string
      path        = string
      description = optional(string)
    })), [])
  }))
  default = {}
}

# Regional Load Balancers
variable "regional_load_balancers" {
  description = "Regional load balancer configurations"
  type = map(object({
    region = string
  }))
  default = {}
}

# SSL Certificates
variable "ssl_certificates" {
  description = "SSL certificate configurations"
  type = map(object({
    domains = list(string)
  }))
  default = {}
}

# SSL Policies
variable "ssl_policies" {
  description = "SSL policy configurations"
  type = map(object({
    profile         = optional(string, "COMPATIBLE")
    min_tls_version = optional(string, "TLS_1_2")
    custom_features = optional(list(string))
  }))
  default = {}
}

# Backend Services
variable "global_backend_services" {
  description = "Global backend service configurations"
  type = map(object({
    protocol                        = optional(string, "HTTP")
    timeout_sec                     = optional(number, 30)
    enable_cdn                      = optional(bool, false)
    compression_mode                = optional(string, "DISABLED")
    session_affinity                = optional(string, "NONE")
    locality_lb_policy              = optional(string, "ROUND_ROBIN")
    connection_draining_timeout_sec = optional(number, 300)
    health_check_key                = string
    security_policy_key             = optional(string)

    backends = list(object({
      group                        = string
      balancing_mode               = optional(string, "UTILIZATION")
      capacity_scaler              = optional(number, 1.0)
      description                  = optional(string)
      max_connections              = optional(number)
      max_connections_per_instance = optional(number)
      max_connections_per_endpoint = optional(number)
      max_rate                     = optional(number)
      max_rate_per_instance        = optional(number)
      max_rate_per_endpoint        = optional(number)
      max_utilization              = optional(number, 0.8)
    }))

    cdn_policy = optional(object({
      cache_mode                   = optional(string, "CACHE_ALL_STATIC")
      signed_url_cache_max_age_sec = optional(number, 7200)
      default_ttl                  = optional(number, 3600)
      max_ttl                      = optional(number, 86400)
      client_ttl                   = optional(number, 3600)
      negative_caching             = optional(bool, false)
      serve_while_stale            = optional(number, 86400)

      cache_key_policy = optional(object({
        include_host           = optional(bool, true)
        include_protocol       = optional(bool, true)
        include_query_string   = optional(bool, true)
        query_string_whitelist = optional(list(string))
        query_string_blacklist = optional(list(string))
        include_http_headers   = optional(list(string))
        include_named_cookies  = optional(list(string))
      }))

      negative_caching_policy = optional(list(object({
        code = number
        ttl  = optional(number, 120)
      })), [])
    }))

    iap_config = optional(object({
      oauth2_client_id     = string
      oauth2_client_secret = string
    }))

    custom_request_headers  = optional(list(string), [])
    custom_response_headers = optional(list(string), [])
  }))
  default = {}
}

# Health Checks
variable "health_checks" {
  description = "Health check configurations"
  type = map(object({
    check_interval_sec  = optional(number, 5)
    timeout_sec         = optional(number, 5)
    healthy_threshold   = optional(number, 2)
    unhealthy_threshold = optional(number, 3)
    enable_logging      = optional(bool, false)

    http_health_check = optional(object({
      host               = optional(string)
      request_path       = optional(string, "/")
      port               = optional(number, 80)
      port_name          = optional(string)
      proxy_header       = optional(string, "NONE")
      response           = optional(string)
      port_specification = optional(string, "USE_FIXED_PORT")
    }))

    https_health_check = optional(object({
      host               = optional(string)
      request_path       = optional(string, "/")
      port               = optional(number, 443)
      port_name          = optional(string)
      proxy_header       = optional(string, "NONE")
      response           = optional(string)
      port_specification = optional(string, "USE_FIXED_PORT")
    }))

    tcp_health_check = optional(object({
      port               = optional(number, 80)
      port_name          = optional(string)
      proxy_header       = optional(string, "NONE")
      request            = optional(string)
      response           = optional(string)
      port_specification = optional(string, "USE_FIXED_PORT")
    }))

    ssl_health_check = optional(object({
      port               = optional(number, 443)
      port_name          = optional(string)
      proxy_header       = optional(string, "NONE")
      request            = optional(string)
      response           = optional(string)
      port_specification = optional(string, "USE_FIXED_PORT")
    }))

    grpc_health_check = optional(object({
      port               = optional(number, 443)
      port_name          = optional(string)
      port_specification = optional(string, "USE_FIXED_PORT")
      grpc_service_name  = optional(string)
    }))
  }))
  default = {}
}

# Security Policies (Cloud Armor)
variable "security_policies" {
  description = "Cloud Armor security policy configurations"
  type = map(object({
    description = optional(string, "Security policy")

    rules = list(object({
      action      = string # "allow", "deny", "redirect", "rate_based_ban"
      priority    = number
      description = optional(string)

      match = optional(object({
        versioned_expr = optional(string, "SRC_IPS_V1")

        config = optional(object({
          src_ip_ranges = list(string)
        }))

        expr = optional(object({
          expression = string
        }))
      }))
    }))

    adaptive_protection_config = optional(object({
      layer_7_ddos_defense_enable          = optional(bool, false)
      layer_7_ddos_defense_rule_visibility = optional(string, "STANDARD")
    }))
  }))
  default = {}
}
