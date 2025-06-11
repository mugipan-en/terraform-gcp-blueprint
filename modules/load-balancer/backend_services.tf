# Backend services for global load balancers
resource "google_compute_backend_service" "global_backend_services" {
  for_each = var.global_backend_services

  name                  = "${var.name_prefix}-${each.key}-backend"
  protocol              = each.value.protocol
  timeout_sec           = each.value.timeout_sec
  enable_cdn           = each.value.enable_cdn
  compression_mode     = each.value.compression_mode
  session_affinity     = each.value.session_affinity
  locality_lb_policy   = each.value.locality_lb_policy
  
  # Health check
  health_checks = [google_compute_health_check.health_checks[each.value.health_check_key].id]

  # Backend configuration
  dynamic "backend" {
    for_each = each.value.backends
    content {
      group           = backend.value.group
      balancing_mode  = backend.value.balancing_mode
      capacity_scaler = backend.value.capacity_scaler
      description     = backend.value.description
      max_connections = backend.value.max_connections
      max_connections_per_instance = backend.value.max_connections_per_instance
      max_connections_per_endpoint = backend.value.max_connections_per_endpoint
      max_rate        = backend.value.max_rate
      max_rate_per_instance = backend.value.max_rate_per_instance
      max_rate_per_endpoint = backend.value.max_rate_per_endpoint
      max_utilization = backend.value.max_utilization
    }
  }

  # CDN policy
  dynamic "cdn_policy" {
    for_each = each.value.cdn_policy != null ? [each.value.cdn_policy] : []
    content {
      cache_mode                   = cdn_policy.value.cache_mode
      signed_url_cache_max_age_sec = cdn_policy.value.signed_url_cache_max_age_sec
      default_ttl                  = cdn_policy.value.default_ttl
      max_ttl                      = cdn_policy.value.max_ttl
      client_ttl                   = cdn_policy.value.client_ttl
      negative_caching             = cdn_policy.value.negative_caching
      serve_while_stale            = cdn_policy.value.serve_while_stale

      dynamic "cache_key_policy" {
        for_each = cdn_policy.value.cache_key_policy != null ? [cdn_policy.value.cache_key_policy] : []
        content {
          include_host           = cache_key_policy.value.include_host
          include_protocol       = cache_key_policy.value.include_protocol
          include_query_string   = cache_key_policy.value.include_query_string
          query_string_whitelist = cache_key_policy.value.query_string_whitelist
          query_string_blacklist = cache_key_policy.value.query_string_blacklist
          include_http_headers   = cache_key_policy.value.include_http_headers
          include_named_cookies  = cache_key_policy.value.include_named_cookies
        }
      }

      dynamic "negative_caching_policy" {
        for_each = cdn_policy.value.negative_caching_policy
        content {
          code = negative_caching_policy.value.code
          ttl  = negative_caching_policy.value.ttl
        }
      }
    }
  }

  # Security policy
  security_policy = try(google_compute_security_policy.security_policies[each.value.security_policy_key].id, null)

  # IAP configuration
  dynamic "iap" {
    for_each = each.value.iap_config != null ? [each.value.iap_config] : []
    content {
      oauth2_client_id     = iap.value.oauth2_client_id
      oauth2_client_secret = iap.value.oauth2_client_secret
    }
  }

  # Connection draining
  connection_draining_timeout_sec = each.value.connection_draining_timeout_sec

  # Custom request headers
  dynamic "custom_request_headers" {
    for_each = each.value.custom_request_headers
    content {
      headers = custom_request_headers.value
    }
  }

  # Custom response headers
  dynamic "custom_response_headers" {
    for_each = each.value.custom_response_headers
    content {
      headers = custom_response_headers.value
    }
  }
}