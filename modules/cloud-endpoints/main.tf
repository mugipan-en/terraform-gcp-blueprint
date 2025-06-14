# Cloud Endpoints Module
# This module creates Google Cloud Endpoints for API management with the following components:
# - Endpoints Services (main.tf)
# - Service IAM bindings (iam.tf)
# - Service consumers (consumers.tf)

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Endpoints Service
resource "google_endpoints_service" "endpoints_services" {
  for_each = var.endpoints_services

  service_name   = each.value.service_name
  project        = var.project_id
  openapi_config = each.value.openapi_config
  grpc_config    = each.value.grpc_config
  protoc_output  = each.value.protoc_output

  lifecycle {
    create_before_destroy = true
  }
}
