# SSL certificates
resource "google_compute_managed_ssl_certificate" "ssl_certs" {
  for_each = var.ssl_certificates

  name = "${var.name_prefix}-${each.key}-cert"

  managed {
    domains = each.value.domains
  }

  lifecycle {
    create_before_destroy = true
  }
}

# SSL policies
resource "google_compute_ssl_policy" "ssl_policies" {
  for_each = var.ssl_policies

  name            = "${var.name_prefix}-${each.key}-ssl-policy"
  profile         = each.value.profile
  min_tls_version = each.value.min_tls_version
  custom_features = each.value.custom_features
}
