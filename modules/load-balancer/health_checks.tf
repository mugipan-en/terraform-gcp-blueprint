# Health checks
resource "google_compute_health_check" "health_checks" {
  for_each = var.health_checks

  name                = "${var.name_prefix}-${each.key}-hc"
  check_interval_sec  = each.value.check_interval_sec
  timeout_sec         = each.value.timeout_sec
  healthy_threshold   = each.value.healthy_threshold
  unhealthy_threshold = each.value.unhealthy_threshold

  dynamic "http_health_check" {
    for_each = each.value.http_health_check != null ? [each.value.http_health_check] : []
    content {
      host               = http_health_check.value.host
      request_path       = http_health_check.value.request_path
      port               = http_health_check.value.port
      port_name          = http_health_check.value.port_name
      proxy_header       = http_health_check.value.proxy_header
      response           = http_health_check.value.response
      port_specification = http_health_check.value.port_specification
    }
  }

  dynamic "https_health_check" {
    for_each = each.value.https_health_check != null ? [each.value.https_health_check] : []
    content {
      host               = https_health_check.value.host
      request_path       = https_health_check.value.request_path
      port               = https_health_check.value.port
      port_name          = https_health_check.value.port_name
      proxy_header       = https_health_check.value.proxy_header
      response           = https_health_check.value.response
      port_specification = https_health_check.value.port_specification
    }
  }

  dynamic "tcp_health_check" {
    for_each = each.value.tcp_health_check != null ? [each.value.tcp_health_check] : []
    content {
      port               = tcp_health_check.value.port
      port_name          = tcp_health_check.value.port_name
      proxy_header       = tcp_health_check.value.proxy_header
      request            = tcp_health_check.value.request
      response           = tcp_health_check.value.response
      port_specification = tcp_health_check.value.port_specification
    }
  }

  dynamic "ssl_health_check" {
    for_each = each.value.ssl_health_check != null ? [each.value.ssl_health_check] : []
    content {
      port               = ssl_health_check.value.port
      port_name          = ssl_health_check.value.port_name
      proxy_header       = ssl_health_check.value.proxy_header
      request            = ssl_health_check.value.request
      response           = ssl_health_check.value.response
      port_specification = ssl_health_check.value.port_specification
    }
  }

  dynamic "grpc_health_check" {
    for_each = each.value.grpc_health_check != null ? [each.value.grpc_health_check] : []
    content {
      port               = grpc_health_check.value.port
      port_name          = grpc_health_check.value.port_name
      port_specification = grpc_health_check.value.port_specification
      grpc_service_name  = grpc_health_check.value.grpc_service_name
    }
  }

  dynamic "log_config" {
    for_each = each.value.enable_logging ? [1] : []
    content {
      enable = true
    }
  }
}
