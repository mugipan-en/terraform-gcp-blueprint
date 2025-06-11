# App Engine Module
# This module creates Google App Engine applications with the following components:
# - App Engine Application (main.tf)
# - App Engine Services/Versions (services.tf)
# - Traffic splitting configuration (traffic.tf)
# - Domain mappings (domains.tf)
# - Firewall rules (firewall.tf)

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# App Engine Application
resource "google_app_engine_application" "app" {
  count = var.create_application ? 1 : 0

  project     = var.project_id
  location_id = var.location_id
  
  dynamic "iap" {
    for_each = var.iap_config != null ? [var.iap_config] : []
    content {
      oauth2_client_id     = iap.value.oauth2_client_id
      oauth2_client_secret = iap.value.oauth2_client_secret
    }
  }

  dynamic "feature_settings" {
    for_each = var.feature_settings != null ? [var.feature_settings] : []
    content {
      split_health_checks = feature_settings.value.split_health_checks
    }
  }
}