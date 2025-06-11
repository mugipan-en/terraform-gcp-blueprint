# App Engine Domain Mappings
resource "google_app_engine_domain_mapping" "domain_mappings" {
  for_each = var.domain_mappings

  project     = var.project_id
  domain_name = each.value.domain_name
  override_strategy = each.value.override_strategy

  dynamic "ssl_settings" {
    for_each = each.value.ssl_settings != null ? [each.value.ssl_settings] : []
    content {
      certificate_id                = ssl_settings.value.certificate_id
      ssl_management_type          = ssl_settings.value.ssl_management_type
      pending_managed_certificate_id = ssl_settings.value.pending_managed_certificate_id
    }
  }

  depends_on = [google_app_engine_application.app]
}

# App Engine Managed SSL Certificates
resource "google_app_engine_managed_ssl_certificate" "managed_certificates" {
  for_each = var.managed_certificates

  project      = var.project_id
  certificate_id = each.key
  display_name = each.value.display_name
  domains      = each.value.domains

  depends_on = [google_app_engine_application.app]
}