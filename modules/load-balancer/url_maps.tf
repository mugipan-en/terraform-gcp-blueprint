# URL maps for global load balancers
resource "google_compute_url_map" "url_maps" {
  for_each = var.global_load_balancers

  name            = "${var.name_prefix}-${each.key}-urlmap"
  default_service = google_compute_backend_service.global_backend_services[each.value.default_backend_service].id

  dynamic "host_rule" {
    for_each = each.value.host_rules
    content {
      hosts        = host_rule.value.hosts
      path_matcher = host_rule.value.path_matcher
    }
  }

  dynamic "path_matcher" {
    for_each = each.value.path_matchers
    content {
      name            = path_matcher.value.name
      default_service = google_compute_backend_service.global_backend_services[path_matcher.value.default_service].id

      dynamic "path_rule" {
        for_each = path_matcher.value.path_rules
        content {
          paths   = path_rule.value.paths
          service = google_compute_backend_service.global_backend_services[path_rule.value.service].id
        }
      }
    }
  }

  dynamic "test" {
    for_each = each.value.url_map_tests
    content {
      service     = google_compute_backend_service.global_backend_services[test.value.service].id
      host        = test.value.host
      path        = test.value.path
      description = test.value.description
    }
  }
}

# Target HTTPS proxy
resource "google_compute_target_https_proxy" "https_proxy" {
  for_each = { for k, v in var.global_load_balancers : k => v if length(v.ssl_certificates) > 0 }

  name             = "${var.name_prefix}-${each.key}-https-proxy"
  url_map          = google_compute_url_map.url_maps[each.key].id
  ssl_certificates = [for cert_key in each.value.ssl_certificates : google_compute_managed_ssl_certificate.ssl_certs[cert_key].id]
  ssl_policy       = try(google_compute_ssl_policy.ssl_policies[each.value.ssl_policy_key].id, null)
}

# Target HTTP proxy
resource "google_compute_target_http_proxy" "http_proxy" {
  for_each = var.global_load_balancers

  name    = "${var.name_prefix}-${each.key}-http-proxy"
  url_map = google_compute_url_map.url_maps[each.key].id
}