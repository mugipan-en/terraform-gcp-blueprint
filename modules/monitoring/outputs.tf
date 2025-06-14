output "email_notification_channels" {
  description = "Email notification channels"
  value = {
    for k, v in google_monitoring_notification_channel.email : k => {
      name         = v.name
      display_name = v.display_name
      type         = v.type
      enabled      = v.enabled
    }
  }
}

output "slack_notification_channels" {
  description = "Slack notification channels"
  value = {
    for k, v in google_monitoring_notification_channel.slack : k => {
      name         = v.name
      display_name = v.display_name
      type         = v.type
      enabled      = v.enabled
    }
  }
}

output "pagerduty_notification_channels" {
  description = "PagerDuty notification channels"
  value = {
    for k, v in google_monitoring_notification_channel.pagerduty : k => {
      name         = v.name
      display_name = v.display_name
      type         = v.type
      enabled      = v.enabled
    }
  }
}

output "cpu_alert_policies" {
  description = "CPU usage alert policies"
  value = {
    for k, v in google_monitoring_alert_policy.cpu_usage : k => {
      name         = v.name
      display_name = v.display_name
      enabled      = v.enabled
    }
  }
}

output "memory_alert_policies" {
  description = "Memory usage alert policies"
  value = {
    for k, v in google_monitoring_alert_policy.memory_usage : k => {
      name         = v.name
      display_name = v.display_name
      enabled      = v.enabled
    }
  }
}

output "disk_alert_policies" {
  description = "Disk usage alert policies"
  value = {
    for k, v in google_monitoring_alert_policy.disk_usage : k => {
      name         = v.name
      display_name = v.display_name
      enabled      = v.enabled
    }
  }
}

output "custom_alert_policies" {
  description = "Custom alert policies"
  value = {
    for k, v in google_monitoring_alert_policy.custom : k => {
      name         = v.name
      display_name = v.display_name
      enabled      = v.enabled
    }
  }
}

output "uptime_checks" {
  description = "Uptime check configurations"
  value = {
    for k, v in google_monitoring_uptime_check_config.http_checks : k => {
      name            = v.name
      display_name    = v.display_name
      uptime_check_id = v.uptime_check_id
    }
  }
}

output "dashboards" {
  description = "Monitoring dashboards"
  value = {
    for k, v in google_monitoring_dashboard.main : k => {
      id = v.id
    }
  }
}

output "log_based_metrics" {
  description = "Log-based metrics"
  value = {
    for k, v in google_logging_metric.custom_metrics : k => {
      name   = v.name
      filter = v.filter
    }
  }
}
