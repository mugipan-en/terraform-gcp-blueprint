variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "bucket_configs" {
  description = "Configuration for Cloud Storage buckets"
  type = map(object({
    location                    = string
    storage_class               = string
    force_destroy               = bool
    uniform_bucket_level_access = bool
    public_access_prevention    = string
    versioning_enabled          = bool
    kms_key_name                = string
    access_logs_bucket          = string
    access_logs_prefix          = string
    labels                      = map(string)

    lifecycle_rules = list(object({
      condition = object({
        age                   = number
        created_before        = string
        with_state            = string
        matches_storage_class = list(string)
        matches_prefix        = list(string)
        matches_suffix        = list(string)
      })
      action = object({
        type          = string
        storage_class = string
      })
    }))

    cors_config = object({
      origin          = list(string)
      method          = list(string)
      response_header = list(string)
      max_age_seconds = number
    })

    website_config = object({
      main_page_suffix = string
      not_found_page   = string
    })

    retention_policy = object({
      is_locked        = bool
      retention_period = number
    })

    notification_configs = list(object({
      topic              = string
      payload_format     = string
      object_name_prefix = string
      event_types        = list(string)
      custom_attributes  = map(string)
    }))
  }))

  default = {
    main = {
      location                    = "ASIA-NORTHEAST1"
      storage_class               = "STANDARD"
      force_destroy               = false
      uniform_bucket_level_access = true
      public_access_prevention    = "enforced"
      versioning_enabled          = true
      kms_key_name                = null
      access_logs_bucket          = null
      access_logs_prefix          = null
      labels                      = {}
      lifecycle_rules             = []
      cors_config                 = null
      website_config              = null
      retention_policy            = null
      notification_configs        = []
    }
  }
}

variable "bucket_iam_bindings" {
  description = "IAM bindings for buckets"
  type = map(object({
    bucket_name = string
    role        = string
    members     = list(string)
    condition = object({
      title       = string
      description = string
      expression  = string
    })
  }))
  default = {}
}

variable "default_objects" {
  description = "Default objects to create in buckets"
  type = map(object({
    bucket_name      = string
    name             = string
    source           = string
    content_type     = string
    content_encoding = string
    content_language = string
    cache_control    = string
    metadata         = map(string)
  }))
  default = {}
}

variable "transfer_jobs" {
  description = "Cloud Storage Transfer Service jobs"
  type = map(object({
    description                              = string
    source_bucket                            = string
    source_path                              = string
    destination_bucket                       = string
    destination_path                         = string
    max_time_elapsed_since_last_modification = string
    min_time_elapsed_since_last_modification = string
    include_prefixes                         = list(string)
    exclude_prefixes                         = list(string)
    overwrite_existing                       = bool
    delete_unique_in_sink                    = bool
    delete_from_source                       = bool
    enabled                                  = bool
    repeat_interval                          = string

    schedule_start_date = object({
      year  = number
      month = number
      day   = number
    })

    schedule_end_date = object({
      year  = number
      month = number
      day   = number
    })

    start_time_of_day = object({
      hours   = number
      minutes = number
      seconds = number
      nanos   = number
    })
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
