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

variable "email_notification_channels" {
  description = "Email notification channels"
  type = map(object({
    display_name  = string
    email_address = string
    enabled       = bool
  }))
  default = {}
}

variable "slack_notification_channels" {
  description = "Slack notification channels"
  type = map(object({
    display_name = string
    channel_name = string
    webhook_url  = string
    auth_token   = string
    enabled      = bool
  }))
  default = {}
}

variable "pagerduty_notification_channels" {
  description = "PagerDuty notification channels"
  type = map(object({
    display_name = string
    service_key  = string
    enabled      = bool
  }))
  default = {}
}

variable "cpu_alert_policies" {
  description = "CPU usage alert policies"
  type = map(object({
    resource_type                           = string
    threshold                              = number
    duration_seconds                       = number
    alignment_period_seconds               = number
    auto_close_duration_seconds            = number
    notification_rate_limit_period_seconds = number
    severity                               = string
    enabled                                = bool
    notification_channels                  = list(string)
  }))
  default = {}
}

variable "memory_alert_policies" {
  description = "Memory usage alert policies"
  type = map(object({
    resource_type                           = string
    threshold                              = number
    duration_seconds                       = number
    alignment_period_seconds               = number
    auto_close_duration_seconds            = number
    notification_rate_limit_period_seconds = number
    severity                               = string
    enabled                                = bool
    notification_channels                  = list(string)
  }))
  default = {}
}

variable "disk_alert_policies" {
  description = "Disk usage alert policies"
  type = map(object({
    resource_type                           = string
    threshold                              = number
    duration_seconds                       = number
    alignment_period_seconds               = number
    auto_close_duration_seconds            = number
    notification_rate_limit_period_seconds = number
    severity                               = string
    enabled                                = bool
    notification_channels                  = list(string)
  }))
  default = {}
}

variable "custom_alert_policies" {
  description = "Custom alert policies"
  type = map(object({
    combiner              = string
    enabled               = bool
    notification_channels = list(string)
    labels               = map(string)
    
    conditions = list(object({
      display_name             = string
      filter                   = string
      duration_seconds         = number
      comparison               = string
      threshold_value          = number
      alignment_period_seconds = number
      per_series_aligner       = string
      cross_series_reducer     = string
      group_by_fields         = list(string)
    }))
    
    alert_strategy = object({
      auto_close_duration_seconds            = number
      notification_rate_limit_period_seconds = number
    })
  }))
  default = {}
}

variable "uptime_check_configs" {
  description = "Uptime check configurations"
  type = map(object({
    timeout_seconds   = number
    period_seconds    = number
    path              = string
    port              = number
    use_ssl          = bool
    validate_ssl     = bool
    resource_type    = string
    resource_labels  = map(string)
    selected_regions = list(string)
    headers          = map(string)
    
    auth_info = object({
      username = string
      password = string
    })
  }))
  default = {}
}

variable "dashboards" {
  description = "Monitoring dashboards"
  type = map(object({
    tiles = list(any)
  }))
  default = {}
}

variable "log_based_metrics" {
  description = "Log-based metrics"
  type = map(object({
    filter = string
    
    metric_descriptor = object({
      metric_kind = string
      value_type  = string
      unit        = string
      
      labels = list(object({
        key         = string
        value_type  = string
        description = string
      }))
    })
    
    label_extractors = map(string)
    
    bucket_options = object({
      linear_buckets = object({
        num_finite_buckets = number
        width              = number
        offset             = number
      })
      
      exponential_buckets = object({
        num_finite_buckets = number
        growth_factor      = number
        scale              = number
      })
    })
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}