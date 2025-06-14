# Global forwarding rules
resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  for_each = { for k, v in var.global_load_balancers : k => v if length(v.ssl_certificates) > 0 }

  name                  = "${var.name_prefix}-${each.key}-https-rule"
  target                = google_compute_target_https_proxy.https_proxy[each.key].id
  port_range            = "443"
  ip_address            = google_compute_global_address.global_ips[each.key].address
  load_balancing_scheme = "EXTERNAL"
}

resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  for_each = var.global_load_balancers

  name                  = "${var.name_prefix}-${each.key}-http-rule"
  target                = google_compute_target_http_proxy.http_proxy[each.key].id
  port_range            = "80"
  ip_address            = google_compute_global_address.global_ips[each.key].address
  load_balancing_scheme = "EXTERNAL"
}
