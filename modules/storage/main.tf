# Cloud Storage Buckets
resource "google_storage_bucket" "buckets" {
  for_each = var.bucket_configs

  name          = "${var.name_prefix}-${each.key}"
  location      = each.value.location
  storage_class = each.value.storage_class
  
  # Force destroy for non-production environments
  force_destroy = each.value.force_destroy

  # Uniform bucket-level access
  uniform_bucket_level_access = each.value.uniform_bucket_level_access

  # Public access prevention
  public_access_prevention = each.value.public_access_prevention

  # Versioning
  dynamic "versioning" {
    for_each = each.value.versioning_enabled ? [1] : []
    content {
      enabled = true
    }
  }

  # Lifecycle management
  dynamic "lifecycle_rule" {
    for_each = each.value.lifecycle_rules
    content {
      condition {
        age                   = lifecycle_rule.value.condition.age
        created_before        = lifecycle_rule.value.condition.created_before
        with_state           = lifecycle_rule.value.condition.with_state
        matches_storage_class = lifecycle_rule.value.condition.matches_storage_class
        matches_prefix       = lifecycle_rule.value.condition.matches_prefix
        matches_suffix       = lifecycle_rule.value.condition.matches_suffix
      }
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lifecycle_rule.value.action.storage_class
      }
    }
  }

  # CORS configuration
  dynamic "cors" {
    for_each = each.value.cors_config != null ? [each.value.cors_config] : []
    content {
      origin          = cors.value.origin
      method          = cors.value.method
      response_header = cors.value.response_header
      max_age_seconds = cors.value.max_age_seconds
    }
  }

  # Website configuration
  dynamic "website" {
    for_each = each.value.website_config != null ? [each.value.website_config] : []
    content {
      main_page_suffix = website.value.main_page_suffix
      not_found_page   = website.value.not_found_page
    }
  }

  # Encryption
  dynamic "encryption" {
    for_each = each.value.kms_key_name != null ? [1] : []
    content {
      default_kms_key_name = each.value.kms_key_name
    }
  }

  # Retention policy
  dynamic "retention_policy" {
    for_each = each.value.retention_policy != null ? [each.value.retention_policy] : []
    content {
      is_locked        = retention_policy.value.is_locked
      retention_period = retention_policy.value.retention_period
    }
  }

  # Logging
  dynamic "logging" {
    for_each = each.value.access_logs_bucket != null ? [1] : []
    content {
      log_bucket        = each.value.access_logs_bucket
      log_object_prefix = each.value.access_logs_prefix
    }
  }

  # Notification configuration
  dynamic "notification" {
    for_each = each.value.notification_configs
    content {
      topic                = notification.value.topic
      payload_format       = notification.value.payload_format
      object_name_prefix   = notification.value.object_name_prefix
      event_types         = notification.value.event_types
      custom_attributes   = notification.value.custom_attributes
    }
  }

  labels = merge(var.tags, each.value.labels, {
    bucket_type = each.key
  })
}

# IAM bindings for buckets
resource "google_storage_bucket_iam_binding" "bucket_bindings" {
  for_each = var.bucket_iam_bindings

  bucket = google_storage_bucket.buckets[each.value.bucket_name].name
  role   = each.value.role

  members = each.value.members

  condition {
    title       = each.value.condition.title
    description = each.value.condition.description
    expression  = each.value.condition.expression
  }
}

# Default objects for buckets
resource "google_storage_bucket_object" "default_objects" {
  for_each = var.default_objects

  name   = each.value.name
  bucket = google_storage_bucket.buckets[each.value.bucket_name].name
  source = each.value.source
  
  content_type     = each.value.content_type
  content_encoding = each.value.content_encoding
  content_language = each.value.content_language
  
  cache_control = each.value.cache_control
  metadata      = each.value.metadata
}

# Cloud Storage Transfer Service (for data migration)
resource "google_storage_transfer_job" "transfer_jobs" {
  for_each = var.transfer_jobs

  description = each.value.description
  
  transfer_spec {
    object_conditions {
      max_time_elapsed_since_last_modification = each.value.max_time_elapsed_since_last_modification
      min_time_elapsed_since_last_modification = each.value.min_time_elapsed_since_last_modification
      include_prefixes                          = each.value.include_prefixes
      exclude_prefixes                          = each.value.exclude_prefixes
    }
    
    dynamic "gcs_data_source" {
      for_each = each.value.source_bucket != null ? [1] : []
      content {
        bucket_name = each.value.source_bucket
        path        = each.value.source_path
      }
    }
    
    gcs_data_sink {
      bucket_name = google_storage_bucket.buckets[each.value.destination_bucket].name
      path        = each.value.destination_path
    }
    
    transfer_options {
      overwrite_objects_already_existing_in_sink = each.value.overwrite_existing
      delete_objects_unique_in_sink              = each.value.delete_unique_in_sink
      delete_objects_from_source_after_transfer = each.value.delete_from_source
    }
  }
  
  schedule {
    schedule_start_date {
      year  = each.value.schedule_start_date.year
      month = each.value.schedule_start_date.month
      day   = each.value.schedule_start_date.day
    }
    
    dynamic "schedule_end_date" {
      for_each = each.value.schedule_end_date != null ? [each.value.schedule_end_date] : []
      content {
        year  = schedule_end_date.value.year
        month = schedule_end_date.value.month
        day   = schedule_end_date.value.day
      }
    }
    
    start_time_of_day {
      hours   = each.value.start_time_of_day.hours
      minutes = each.value.start_time_of_day.minutes
      seconds = each.value.start_time_of_day.seconds
      nanos   = each.value.start_time_of_day.nanos
    }
    
    repeat_interval = each.value.repeat_interval
  }
  
  status = each.value.enabled ? "ENABLED" : "DISABLED"
}