# Cloud Tasks Module
# This module creates Google Cloud Tasks queues and configurations

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Cloud Tasks Queues
resource "google_cloud_tasks_queue" "queues" {
  for_each = var.task_queues

  name     = "${var.name_prefix}-${each.key}"
  location = each.value.location
  project  = var.project_id

  # Rate limits
  dynamic "rate_limits" {
    for_each = each.value.rate_limits != null ? [each.value.rate_limits] : []
    content {
      max_dispatches_per_second = rate_limits.value.max_dispatches_per_second
      max_burst_size            = rate_limits.value.max_burst_size
      max_concurrent_dispatches = rate_limits.value.max_concurrent_dispatches
    }
  }

  # Retry configuration
  dynamic "retry_config" {
    for_each = each.value.retry_config != null ? [each.value.retry_config] : []
    content {
      max_attempts       = retry_config.value.max_attempts
      max_retry_duration = retry_config.value.max_retry_duration
      max_backoff        = retry_config.value.max_backoff
      min_backoff        = retry_config.value.min_backoff
      max_doublings      = retry_config.value.max_doublings
    }
  }

  # Stackdriver logging
  dynamic "stackdriver_logging_config" {
    for_each = each.value.stackdriver_logging_config != null ? [each.value.stackdriver_logging_config] : []
    content {
      sampling_ratio = stackdriver_logging_config.value.sampling_ratio
    }
  }

  # App Engine routing override
  dynamic "app_engine_routing_override" {
    for_each = each.value.app_engine_routing_override != null ? [each.value.app_engine_routing_override] : []
    content {
      service  = app_engine_routing_override.value.service
      version  = app_engine_routing_override.value.version
      instance = app_engine_routing_override.value.instance
    }
  }
}
