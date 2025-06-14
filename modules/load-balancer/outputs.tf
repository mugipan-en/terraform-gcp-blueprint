# Global IP Addresses
output "global_ip_addresses" {
  description = "Global IP addresses for load balancers"
  value = {
    for k, v in google_compute_global_address.global_ips : k => {
      address    = v.address
      ip_version = v.ip_version
      name       = v.name
      self_link  = v.self_link
    }
  }
}

# Regional IP Addresses
output "regional_ip_addresses" {
  description = "Regional IP addresses for load balancers"
  value = {
    for k, v in google_compute_address.regional_ips : k => {
      address   = v.address
      region    = v.region
      name      = v.name
      self_link = v.self_link
    }
  }
}

# SSL Certificates
output "ssl_certificates" {
  description = "SSL certificate information"
  value = {
    for k, v in google_compute_managed_ssl_certificate.ssl_certs : k => {
      name          = v.name
      domains       = v.managed[0].domains
      status        = v.managed[0].status
      domain_status = v.managed[0].domain_status
      self_link     = v.self_link
    }
  }
}

# Backend Services
output "backend_services" {
  description = "Backend service information"
  value = {
    for k, v in google_compute_backend_service.global_backend_services : k => {
      name         = v.name
      protocol     = v.protocol
      timeout_sec  = v.timeout_sec
      enable_cdn   = v.enable_cdn
      self_link    = v.self_link
      generated_id = v.generated_id
      fingerprint  = v.fingerprint
    }
  }
}

# Health Checks
output "health_checks" {
  description = "Health check information"
  value = {
    for k, v in google_compute_health_check.health_checks : k => {
      name                = v.name
      check_interval_sec  = v.check_interval_sec
      timeout_sec         = v.timeout_sec
      healthy_threshold   = v.healthy_threshold
      unhealthy_threshold = v.unhealthy_threshold
      self_link           = v.self_link
    }
  }
}

# URL Maps
output "url_maps" {
  description = "URL map information"
  value = {
    for k, v in google_compute_url_map.url_maps : k => {
      name            = v.name
      default_service = v.default_service
      fingerprint     = v.fingerprint
      self_link       = v.self_link
      map_id          = v.map_id
    }
  }
}

# Target Proxies
output "target_https_proxies" {
  description = "Target HTTPS proxy information"
  value = {
    for k, v in google_compute_target_https_proxy.https_proxy : k => {
      name             = v.name
      url_map          = v.url_map
      ssl_certificates = v.ssl_certificates
      proxy_id         = v.proxy_id
      self_link        = v.self_link
    }
  }
}

output "target_http_proxies" {
  description = "Target HTTP proxy information"
  value = {
    for k, v in google_compute_target_http_proxy.http_proxy : k => {
      name      = v.name
      url_map   = v.url_map
      proxy_id  = v.proxy_id
      self_link = v.self_link
    }
  }
}

# Forwarding Rules
output "https_forwarding_rules" {
  description = "HTTPS forwarding rule information"
  value = {
    for k, v in google_compute_global_forwarding_rule.https_forwarding_rule : k => {
      name                  = v.name
      target                = v.target
      port_range            = v.port_range
      ip_address            = v.ip_address
      load_balancing_scheme = v.load_balancing_scheme
      self_link             = v.self_link
    }
  }
}

output "http_forwarding_rules" {
  description = "HTTP forwarding rule information"
  value = {
    for k, v in google_compute_global_forwarding_rule.http_forwarding_rule : k => {
      name                  = v.name
      target                = v.target
      port_range            = v.port_range
      ip_address            = v.ip_address
      load_balancing_scheme = v.load_balancing_scheme
      self_link             = v.self_link
    }
  }
}

# SSL Policies
output "ssl_policies" {
  description = "SSL policy information"
  value = {
    for k, v in google_compute_ssl_policy.ssl_policies : k => {
      name             = v.name
      profile          = v.profile
      min_tls_version  = v.min_tls_version
      custom_features  = v.custom_features
      enabled_features = v.enabled_features
      fingerprint      = v.fingerprint
      self_link        = v.self_link
    }
  }
}

# Security Policies (Cloud Armor)
output "security_policies" {
  description = "Cloud Armor security policy information"
  value = {
    for k, v in google_compute_security_policy.security_policies : k => {
      name        = v.name
      description = v.description
      fingerprint = v.fingerprint
      self_link   = v.self_link

      # Security policy rules
      rules = [
        for rule in v.rule : {
          action      = rule.action
          priority    = rule.priority
          description = rule.description
        }
      ]
    }
  }
}

# Load Balancer URLs
output "load_balancer_urls" {
  description = "Load balancer access URLs"
  value = {
    for k, v in var.global_load_balancers : k => {
      http_url  = "http://${google_compute_global_address.global_ips[k].address}"
      https_url = length(v.ssl_certificates) > 0 ? "https://${google_compute_global_address.global_ips[k].address}" : null
    }
  }
}

# Load Balancer Summary
output "load_balancer_summary" {
  description = "Summary of all load balancer configurations"
  value = {
    global_load_balancers = {
      for k, v in var.global_load_balancers : k => {
        ip_address       = google_compute_global_address.global_ips[k].address
        ssl_enabled      = length(v.ssl_certificates) > 0
        cdn_enabled      = try(google_compute_backend_service.global_backend_services[v.default_backend_service].enable_cdn, false)
        security_policy  = v.security_policy_key != null ? google_compute_security_policy.security_policies[v.security_policy_key].name : null
        backend_services = v.default_backend_service
      }
    }

    total_certificates      = length(google_compute_managed_ssl_certificate.ssl_certs)
    total_health_checks     = length(google_compute_health_check.health_checks)
    total_backend_services  = length(google_compute_backend_service.global_backend_services)
    total_security_policies = length(google_compute_security_policy.security_policies)
  }
}
