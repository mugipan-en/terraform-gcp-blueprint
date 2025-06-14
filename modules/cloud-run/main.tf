# 🔥 Smart Environment Configuration
locals {
  # Environment-based defaults
  environment_defaults = {
    dev = {
      min_scale             = 0
      max_scale             = 10
      container_concurrency = 80
      cpu_limit             = "1000m"
      memory_limit          = "512Mi"
      timeout_seconds       = 300
      execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
      cpu_throttling        = true
      allow_unauthenticated = true
    }
    staging = {
      min_scale             = 1
      max_scale             = 20
      container_concurrency = 80
      cpu_limit             = "1000m"
      memory_limit          = "1Gi"
      timeout_seconds       = 300
      execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
      cpu_throttling        = true
      allow_unauthenticated = false
    }
    production = {
      min_scale             = 2
      max_scale             = 100
      container_concurrency = 100
      cpu_limit             = "2000m"
      memory_limit          = "2Gi"
      timeout_seconds       = 300
      execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
      cpu_throttling        = false
      allow_unauthenticated = false
    }
  }

  # Merge environment defaults with user configuration for each service
  env_config = local.environment_defaults[var.environment]

  # Final services configuration
  services_config = {
    for name, service in var.services : name => merge(local.env_config, service, {
      location = service.location != null ? service.location : var.region
    })
  }
}

# Cloud Run Services
resource "google_cloud_run_service" "services" {
  for_each = local.services_config

  name     = "${var.name_prefix}-${each.key}"
  location = each.value.location

  template {
    metadata {
      annotations = merge({
        "autoscaling.knative.dev/minScale"         = tostring(each.value.min_scale)
        "autoscaling.knative.dev/maxScale"         = tostring(each.value.max_scale)
        "run.googleapis.com/execution-environment" = each.value.execution_environment
        "run.googleapis.com/cpu-throttling"        = tostring(each.value.cpu_throttling)
      }, each.value.annotations)

      labels = merge(var.tags, each.value.labels)
    }

    spec {
      container_concurrency = each.value.container_concurrency
      timeout_seconds       = each.value.timeout_seconds
      service_account_name  = each.value.service_account_email

      containers {
        image = each.value.image

        # Environment variables
        dynamic "env" {
          for_each = each.value.env_vars
          content {
            name  = env.key
            value = env.value
          }
        }

        # Environment variables from secrets
        dynamic "env" {
          for_each = each.value.env_vars_from_secrets
          content {
            name = env.value.name
            value_from {
              secret_key_ref {
                name = env.value.secret_name
                key  = env.value.key
              }
            }
          }
        }

        # Resources
        resources {
          limits = {
            cpu    = each.value.cpu_limit
            memory = each.value.memory_limit
          }
          requests = {
            cpu    = each.value.cpu_request
            memory = each.value.memory_request
          }
        }

        # Ports
        dynamic "ports" {
          for_each = each.value.ports
          content {
            name           = ports.value.name
            protocol       = ports.value.protocol
            container_port = ports.value.container_port
          }
        }

        # Volume mounts
        dynamic "volume_mounts" {
          for_each = each.value.volume_mounts
          content {
            name       = volume_mounts.value.name
            mount_path = volume_mounts.value.mount_path
          }
        }

        # Startup probe
        dynamic "startup_probe" {
          for_each = each.value.startup_probe != null ? [each.value.startup_probe] : []
          content {
            initial_delay_seconds = startup_probe.value.initial_delay_seconds
            timeout_seconds       = startup_probe.value.timeout_seconds
            period_seconds        = startup_probe.value.period_seconds
            failure_threshold     = startup_probe.value.failure_threshold

            dynamic "http_get" {
              for_each = startup_probe.value.http_get != null ? [startup_probe.value.http_get] : []
              content {
                path = http_get.value.path
                port = http_get.value.port
                dynamic "http_headers" {
                  for_each = http_get.value.http_headers
                  content {
                    name  = http_headers.value.name
                    value = http_headers.value.value
                  }
                }
              }
            }
          }
        }

        # Liveness probe
        dynamic "liveness_probe" {
          for_each = each.value.liveness_probe != null ? [each.value.liveness_probe] : []
          content {
            initial_delay_seconds = liveness_probe.value.initial_delay_seconds
            timeout_seconds       = liveness_probe.value.timeout_seconds
            period_seconds        = liveness_probe.value.period_seconds
            failure_threshold     = liveness_probe.value.failure_threshold

            dynamic "http_get" {
              for_each = liveness_probe.value.http_get != null ? [liveness_probe.value.http_get] : []
              content {
                path = http_get.value.path
                port = http_get.value.port
                dynamic "http_headers" {
                  for_each = http_get.value.http_headers
                  content {
                    name  = http_headers.value.name
                    value = http_headers.value.value
                  }
                }
              }
            }
          }
        }
      }

      # Volumes
      dynamic "volumes" {
        for_each = each.value.volumes
        content {
          name = volumes.value.name

          dynamic "secret" {
            for_each = volumes.value.secret != null ? [volumes.value.secret] : []
            content {
              secret_name  = secret.value.secret_name
              default_mode = secret.value.default_mode
              dynamic "items" {
                for_each = secret.value.items
                content {
                  key  = items.value.key
                  path = items.value.path
                  mode = items.value.mode
                }
              }
            }
          }

          dynamic "config_map" {
            for_each = volumes.value.config_map != null ? [volumes.value.config_map] : []
            content {
              name         = config_map.value.name
              default_mode = config_map.value.default_mode
              dynamic "items" {
                for_each = config_map.value.items
                content {
                  key  = items.value.key
                  path = items.value.path
                  mode = items.value.mode
                }
              }
            }
          }
        }
      }
    }
  }

  # Traffic allocation
  dynamic "traffic" {
    for_each = each.value.traffic_allocation
    content {
      percent         = traffic.value.percent
      latest_revision = traffic.value.latest_revision
      revision_name   = traffic.value.revision_name
      tag             = traffic.value.tag
    }
  }

  # Autogenerate revision names
  autogenerate_revision_name = each.value.autogenerate_revision_name

  lifecycle {
    ignore_changes = [
      template[0].metadata[0].annotations["run.googleapis.com/operation-id"],
    ]
  }
}

# IAM policies for Cloud Run services
resource "google_cloud_run_service_iam_binding" "bindings" {
  for_each = var.iam_bindings

  location = google_cloud_run_service.services[each.value.service_key].location
  project  = google_cloud_run_service.services[each.value.service_key].project
  service  = google_cloud_run_service.services[each.value.service_key].name
  role     = each.value.role
  members  = each.value.members
}

# Domain mappings
resource "google_cloud_run_domain_mapping" "domain_mappings" {
  for_each = var.domain_mappings

  location = google_cloud_run_service.services[each.value.service_key].location
  name     = each.value.domain_name

  metadata {
    namespace   = var.project_id
    labels      = merge(var.tags, each.value.labels)
    annotations = each.value.annotations
  }

  spec {
    route_name = google_cloud_run_service.services[each.value.service_key].name
  }
}

# VPC Connector (if specified)
resource "google_vpc_access_connector" "connector" {
  for_each = var.vpc_connectors

  name          = "${var.name_prefix}-${each.key}-connector"
  ip_cidr_range = each.value.ip_cidr_range
  network       = each.value.network
  region        = each.value.region

  min_throughput = each.value.min_throughput
  max_throughput = each.value.max_throughput

  subnet {
    name       = each.value.subnet_name
    project_id = var.project_id
  }
}
