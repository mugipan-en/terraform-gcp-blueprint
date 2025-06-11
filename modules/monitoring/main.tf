# Notification Channels
resource "google_monitoring_notification_channel" "email" {
  for_each = var.email_notification_channels

  display_name = each.value.display_name
  type         = "email"
  
  labels = {
    email_address = each.value.email_address
  }
  
  user_labels = merge(var.tags, {
    notification_type = "email"
    channel_name     = each.key
  })
  
  enabled = each.value.enabled
}

resource "google_monitoring_notification_channel" "slack" {
  for_each = var.slack_notification_channels

  display_name = each.value.display_name
  type         = "slack"
  
  labels = {
    channel_name = each.value.channel_name
    url          = each.value.webhook_url
  }
  
  user_labels = merge(var.tags, {
    notification_type = "slack"
    channel_name     = each.key
  })
  
  enabled = each.value.enabled
  
  sensitive_labels {
    auth_token = each.value.auth_token
  }
}

resource "google_monitoring_notification_channel" "pagerduty" {
  for_each = var.pagerduty_notification_channels

  display_name = each.value.display_name
  type         = "pagerduty"
  
  labels = {
    service_key = each.value.service_key
  }
  
  user_labels = merge(var.tags, {
    notification_type = "pagerduty"
    channel_name     = each.key
  })
  
  enabled = each.value.enabled
}

# Alert Policies
resource "google_monitoring_alert_policy" "cpu_usage" {
  for_each = var.cpu_alert_policies

  display_name          = "${var.name_prefix}-cpu-usage-${each.key}"
  combiner              = "OR"
  enabled               = each.value.enabled
  notification_channels = [for channel in each.value.notification_channels : 
    try(google_monitoring_notification_channel.email[channel].name, 
        google_monitoring_notification_channel.slack[channel].name,
        google_monitoring_notification_channel.pagerduty[channel].name)]

  conditions {
    display_name = "CPU usage is high"
    
    condition_threshold {
      filter          = "resource.type=\"${each.value.resource_type}\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
      duration        = "${each.value.duration_seconds}s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = each.value.threshold
      
      aggregations {
        alignment_period   = "${each.value.alignment_period_seconds}s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  alert_strategy {
    auto_close = "${each.value.auto_close_duration_seconds}s"
    
    notification_rate_limit {
      period = "${each.value.notification_rate_limit_period_seconds}s"
    }
  }

  user_labels = merge(var.tags, {
    alert_type = "cpu_usage"
    severity   = each.value.severity
  })
}

resource "google_monitoring_alert_policy" "memory_usage" {
  for_each = var.memory_alert_policies

  display_name          = "${var.name_prefix}-memory-usage-${each.key}"
  combiner              = "OR"
  enabled               = each.value.enabled
  notification_channels = [for channel in each.value.notification_channels : 
    try(google_monitoring_notification_channel.email[channel].name, 
        google_monitoring_notification_channel.slack[channel].name,
        google_monitoring_notification_channel.pagerduty[channel].name)]

  conditions {
    display_name = "Memory usage is high"
    
    condition_threshold {
      filter          = "resource.type=\"${each.value.resource_type}\" AND metric.type=\"compute.googleapis.com/instance/memory/utilization\""
      duration        = "${each.value.duration_seconds}s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = each.value.threshold
      
      aggregations {
        alignment_period   = "${each.value.alignment_period_seconds}s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  user_labels = merge(var.tags, {
    alert_type = "memory_usage"
    severity   = each.value.severity
  })
}

resource "google_monitoring_alert_policy" "disk_usage" {
  for_each = var.disk_alert_policies

  display_name          = "${var.name_prefix}-disk-usage-${each.key}"
  combiner              = "OR"
  enabled               = each.value.enabled
  notification_channels = [for channel in each.value.notification_channels : 
    try(google_monitoring_notification_channel.email[channel].name, 
        google_monitoring_notification_channel.slack[channel].name,
        google_monitoring_notification_channel.pagerduty[channel].name)]

  conditions {
    display_name = "Disk usage is high"
    
    condition_threshold {
      filter          = "resource.type=\"${each.value.resource_type}\" AND metric.type=\"compute.googleapis.com/instance/disk/utilization\""
      duration        = "${each.value.duration_seconds}s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = each.value.threshold
      
      aggregations {
        alignment_period   = "${each.value.alignment_period_seconds}s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  user_labels = merge(var.tags, {
    alert_type = "disk_usage"
    severity   = each.value.severity
  })
}

# Custom Alert Policies
resource "google_monitoring_alert_policy" "custom" {
  for_each = var.custom_alert_policies

  display_name          = "${var.name_prefix}-${each.key}"
  combiner              = each.value.combiner
  enabled               = each.value.enabled
  notification_channels = [for channel in each.value.notification_channels : 
    try(google_monitoring_notification_channel.email[channel].name, 
        google_monitoring_notification_channel.slack[channel].name,
        google_monitoring_notification_channel.pagerduty[channel].name)]

  dynamic "conditions" {
    for_each = each.value.conditions
    content {
      display_name = conditions.value.display_name
      
      condition_threshold {
        filter          = conditions.value.filter
        duration        = "${conditions.value.duration_seconds}s"
        comparison      = conditions.value.comparison
        threshold_value = conditions.value.threshold_value
        
        aggregations {
          alignment_period     = "${conditions.value.alignment_period_seconds}s"
          per_series_aligner   = conditions.value.per_series_aligner
          cross_series_reducer = conditions.value.cross_series_reducer
          group_by_fields      = conditions.value.group_by_fields
        }
      }
    }
  }

  dynamic "alert_strategy" {
    for_each = each.value.alert_strategy != null ? [each.value.alert_strategy] : []
    content {
      auto_close = "${alert_strategy.value.auto_close_duration_seconds}s"
      
      notification_rate_limit {
        period = "${alert_strategy.value.notification_rate_limit_period_seconds}s"
      }
    }
  }

  user_labels = merge(var.tags, each.value.labels)
}

# Uptime Checks
resource "google_monitoring_uptime_check_config" "http_checks" {
  for_each = var.uptime_check_configs

  display_name = "${var.name_prefix}-uptime-${each.key}"
  timeout      = "${each.value.timeout_seconds}s"
  period       = "${each.value.period_seconds}s"

  http_check {
    path         = each.value.path
    port         = each.value.port
    use_ssl      = each.value.use_ssl
    validate_ssl = each.value.validate_ssl
    
    dynamic "auth_info" {
      for_each = each.value.auth_info != null ? [each.value.auth_info] : []
      content {
        username = auth_info.value.username
        password = auth_info.value.password
      }
    }
    
    dynamic "headers" {
      for_each = each.value.headers
      content {
        key   = headers.key
        value = headers.value
      }
    }
  }

  monitored_resource {
    type = each.value.resource_type
    labels = each.value.resource_labels
  }

  dynamic "selected_regions" {
    for_each = length(each.value.selected_regions) > 0 ? [1] : []
    content {
      regions = each.value.selected_regions
    }
  }

  user_labels = merge(var.tags, {
    check_type = "uptime"
    target     = each.key
  })
}

# Dashboards
resource "google_monitoring_dashboard" "main" {
  for_each = var.dashboards

  dashboard_json = jsonencode({
    displayName = "${var.name_prefix}-${each.key}-dashboard"
    mosaicLayout = {
      tiles = each.value.tiles
    }
    labels = merge(var.tags, {
      dashboard_type = each.key
    })
  })
}

# Log-based Metrics
resource "google_logging_metric" "custom_metrics" {
  for_each = var.log_based_metrics

  name   = "${var.name_prefix}-${each.key}"
  filter = each.value.filter

  dynamic "metric_descriptor" {
    for_each = each.value.metric_descriptor != null ? [each.value.metric_descriptor] : []
    content {
      metric_kind = metric_descriptor.value.metric_kind
      value_type  = metric_descriptor.value.value_type
      unit        = metric_descriptor.value.unit
      
      dynamic "labels" {
        for_each = metric_descriptor.value.labels
        content {
          key         = labels.value.key
          value_type  = labels.value.value_type
          description = labels.value.description
        }
      }
    }
  }

  dynamic "label_extractors" {
    for_each = each.value.label_extractors
    content {
      for k, v in label_extractors.value : k => v
    }
  }

  dynamic "bucket_options" {
    for_each = each.value.bucket_options != null ? [each.value.bucket_options] : []
    content {
      dynamic "linear_buckets" {
        for_each = bucket_options.value.linear_buckets != null ? [bucket_options.value.linear_buckets] : []
        content {
          num_finite_buckets = linear_buckets.value.num_finite_buckets
          width              = linear_buckets.value.width
          offset             = linear_buckets.value.offset
        }
      }
      
      dynamic "exponential_buckets" {
        for_each = bucket_options.value.exponential_buckets != null ? [bucket_options.value.exponential_buckets] : []
        content {
          num_finite_buckets = exponential_buckets.value.num_finite_buckets
          growth_factor      = exponential_buckets.value.growth_factor
          scale              = exponential_buckets.value.scale
        }
      }
    }
  }
}