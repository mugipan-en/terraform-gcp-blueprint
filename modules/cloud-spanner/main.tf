# Cloud Spanner Module
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Spanner Instance
resource "google_spanner_instance" "instances" {
  for_each = var.spanner_instances

  config           = each.value.config
  display_name     = each.value.display_name
  name             = "${var.name_prefix}-${each.key}"
  num_nodes        = each.value.num_nodes
  processing_units = each.value.processing_units
  project          = var.project_id
  labels           = merge(var.tags, each.value.labels)
  force_destroy    = each.value.force_destroy

  dynamic "autoscaling_config" {
    for_each = each.value.autoscaling_config != null ? [each.value.autoscaling_config] : []
    content {
      autoscaling_limits {
        max_nodes            = autoscaling_config.value.autoscaling_limits.max_nodes
        max_processing_units = autoscaling_config.value.autoscaling_limits.max_processing_units
        min_nodes            = autoscaling_config.value.autoscaling_limits.min_nodes
        min_processing_units = autoscaling_config.value.autoscaling_limits.min_processing_units
      }
      autoscaling_targets {
        high_priority_cpu_utilization_percent = autoscaling_config.value.autoscaling_targets.high_priority_cpu_utilization_percent
        storage_utilization_percent           = autoscaling_config.value.autoscaling_targets.storage_utilization_percent
      }
    }
  }
}

# Spanner Database
resource "google_spanner_database" "databases" {
  for_each = var.spanner_databases

  instance                 = google_spanner_instance.instances[each.value.instance_key].name
  name                     = each.value.name
  project                  = var.project_id
  version_retention_period = each.value.version_retention_period
  ddl                      = each.value.ddl
  deletion_protection      = each.value.deletion_protection

  dynamic "encryption_config" {
    for_each = each.value.encryption_config != null ? [each.value.encryption_config] : []
    content {
      kms_key_name = encryption_config.value.kms_key_name
    }
  }
}
