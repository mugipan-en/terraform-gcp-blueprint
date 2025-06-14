# App Engine Standard Services
resource "google_app_engine_standard_app_version" "standard_versions" {
  for_each = var.standard_services

  project    = var.project_id
  service    = each.value.service_name
  version_id = each.value.version_id
  runtime    = each.value.runtime
  threadsafe = each.value.threadsafe

  # Deployment configuration
  dynamic "deployment" {
    for_each = each.value.deployment != null ? [each.value.deployment] : []
    content {
      dynamic "zip" {
        for_each = deployment.value.zip != null ? [deployment.value.zip] : []
        content {
          source_url  = zip.value.source_url
          files_count = zip.value.files_count
        }
      }

      dynamic "files" {
        for_each = deployment.value.files != null ? deployment.value.files : {}
        content {
          name       = files.key
          source_url = files.value.source_url
          sha1_sum   = files.value.sha1_sum
        }
      }
    }
  }

  # Entrypoint
  dynamic "entrypoint" {
    for_each = each.value.entrypoint != null ? [each.value.entrypoint] : []
    content {
      shell = entrypoint.value.shell
    }
  }

  # Environment variables
  env_variables = each.value.env_variables

  # Instance class
  instance_class = each.value.instance_class

  # Automatic scaling
  dynamic "automatic_scaling" {
    for_each = each.value.automatic_scaling != null ? [each.value.automatic_scaling] : []
    content {
      max_concurrent_requests = automatic_scaling.value.max_concurrent_requests
      max_idle_instances      = automatic_scaling.value.max_idle_instances
      max_pending_latency     = automatic_scaling.value.max_pending_latency
      min_idle_instances      = automatic_scaling.value.min_idle_instances
      min_pending_latency     = automatic_scaling.value.min_pending_latency

      dynamic "standard_scheduler_settings" {
        for_each = automatic_scaling.value.standard_scheduler_settings != null ? [automatic_scaling.value.standard_scheduler_settings] : []
        content {
          target_cpu_utilization        = standard_scheduler_settings.value.target_cpu_utilization
          target_throughput_utilization = standard_scheduler_settings.value.target_throughput_utilization
          min_instances                 = standard_scheduler_settings.value.min_instances
          max_instances                 = standard_scheduler_settings.value.max_instances
        }
      }
    }
  }

  # Basic scaling
  dynamic "basic_scaling" {
    for_each = each.value.basic_scaling != null ? [each.value.basic_scaling] : []
    content {
      idle_timeout  = basic_scaling.value.idle_timeout
      max_instances = basic_scaling.value.max_instances
    }
  }

  # Manual scaling
  dynamic "manual_scaling" {
    for_each = each.value.manual_scaling != null ? [each.value.manual_scaling] : []
    content {
      instances = manual_scaling.value.instances
    }
  }

  # VPC access connector
  dynamic "vpc_access_connector" {
    for_each = each.value.vpc_access_connector != null ? [each.value.vpc_access_connector] : []
    content {
      name = vpc_access_connector.value.name
    }
  }

  # Handlers
  dynamic "handlers" {
    for_each = each.value.handlers != null ? each.value.handlers : []
    content {
      url_regex                   = handlers.value.url_regex
      security_level              = handlers.value.security_level
      login                       = handlers.value.login
      auth_fail_action            = handlers.value.auth_fail_action
      redirect_http_response_code = handlers.value.redirect_http_response_code

      dynamic "script" {
        for_each = handlers.value.script != null ? [handlers.value.script] : []
        content {
          script_path = script.value.script_path
        }
      }

      dynamic "static_files" {
        for_each = handlers.value.static_files != null ? [handlers.value.static_files] : []
        content {
          path                  = static_files.value.path
          upload_path_regex     = static_files.value.upload_path_regex
          http_headers          = static_files.value.http_headers
          mime_type             = static_files.value.mime_type
          expiration            = static_files.value.expiration
          require_matching_file = static_files.value.require_matching_file
        }
      }
    }
  }

  # Libraries
  dynamic "libraries" {
    for_each = each.value.libraries != null ? each.value.libraries : []
    content {
      name    = libraries.value.name
      version = libraries.value.version
    }
  }

  # Inbound services
  inbound_services = each.value.inbound_services

  # No traffic on deploy
  noop_on_destroy           = each.value.noop_on_destroy
  delete_service_on_destroy = each.value.delete_service_on_destroy

  depends_on = [google_app_engine_application.app]
}

# App Engine Flexible Services
resource "google_app_engine_flexible_app_version" "flexible_versions" {
  for_each = var.flexible_services

  project    = var.project_id
  service    = each.value.service_name
  version_id = each.value.version_id
  runtime    = each.value.runtime

  # Deployment configuration
  dynamic "deployment" {
    for_each = each.value.deployment != null ? [each.value.deployment] : []
    content {
      dynamic "container" {
        for_each = deployment.value.container != null ? [deployment.value.container] : []
        content {
          image = container.value.image
        }
      }

      dynamic "zip" {
        for_each = deployment.value.zip != null ? [deployment.value.zip] : []
        content {
          source_url  = zip.value.source_url
          files_count = zip.value.files_count
        }
      }

      dynamic "files" {
        for_each = deployment.value.files != null ? deployment.value.files : {}
        content {
          name       = files.key
          source_url = files.value.source_url
          sha1_sum   = files.value.sha1_sum
        }
      }
    }
  }

  # Entrypoint
  dynamic "entrypoint" {
    for_each = each.value.entrypoint != null ? [each.value.entrypoint] : []
    content {
      shell = entrypoint.value.shell
    }
  }

  # Runtime configuration
  dynamic "runtime_config" {
    for_each = each.value.runtime_config != null ? [each.value.runtime_config] : []
    content {
      operating_system = runtime_config.value.operating_system
      runtime_version  = runtime_config.value.runtime_version
    }
  }

  # Environment variables
  env_variables = each.value.env_variables

  # Automatic scaling
  dynamic "automatic_scaling" {
    for_each = each.value.automatic_scaling != null ? [each.value.automatic_scaling] : []
    content {
      cool_down_period        = automatic_scaling.value.cool_down_period
      max_concurrent_requests = automatic_scaling.value.max_concurrent_requests
      max_idle_instances      = automatic_scaling.value.max_idle_instances
      max_pending_latency     = automatic_scaling.value.max_pending_latency
      max_total_instances     = automatic_scaling.value.max_total_instances
      min_idle_instances      = automatic_scaling.value.min_idle_instances
      min_pending_latency     = automatic_scaling.value.min_pending_latency
      min_total_instances     = automatic_scaling.value.min_total_instances

      dynamic "cpu_utilization" {
        for_each = automatic_scaling.value.cpu_utilization != null ? [automatic_scaling.value.cpu_utilization] : []
        content {
          aggregation_window_length = cpu_utilization.value.aggregation_window_length
          target_utilization        = cpu_utilization.value.target_utilization
        }
      }

      dynamic "disk_utilization" {
        for_each = automatic_scaling.value.disk_utilization != null ? [automatic_scaling.value.disk_utilization] : []
        content {
          target_read_bytes_per_second  = disk_utilization.value.target_read_bytes_per_second
          target_read_ops_per_second    = disk_utilization.value.target_read_ops_per_second
          target_write_bytes_per_second = disk_utilization.value.target_write_bytes_per_second
          target_write_ops_per_second   = disk_utilization.value.target_write_ops_per_second
        }
      }

      dynamic "network_utilization" {
        for_each = automatic_scaling.value.network_utilization != null ? [automatic_scaling.value.network_utilization] : []
        content {
          target_received_bytes_per_second   = network_utilization.value.target_received_bytes_per_second
          target_received_packets_per_second = network_utilization.value.target_received_packets_per_second
          target_sent_bytes_per_second       = network_utilization.value.target_sent_bytes_per_second
          target_sent_packets_per_second     = network_utilization.value.target_sent_packets_per_second
        }
      }

      dynamic "request_utilization" {
        for_each = automatic_scaling.value.request_utilization != null ? [automatic_scaling.value.request_utilization] : []
        content {
          target_concurrent_requests      = request_utilization.value.target_concurrent_requests
          target_request_count_per_second = request_utilization.value.target_request_count_per_second
        }
      }
    }
  }

  # Manual scaling
  dynamic "manual_scaling" {
    for_each = each.value.manual_scaling != null ? [each.value.manual_scaling] : []
    content {
      instances = manual_scaling.value.instances
    }
  }

  # VPC access connector
  dynamic "vpc_access_connector" {
    for_each = each.value.vpc_access_connector != null ? [each.value.vpc_access_connector] : []
    content {
      name = vpc_access_connector.value.name
    }
  }

  # Resources
  dynamic "resources" {
    for_each = each.value.resources != null ? [each.value.resources] : []
    content {
      cpu       = resources.value.cpu
      memory_gb = resources.value.memory_gb
      disk_gb   = resources.value.disk_gb

      dynamic "volumes" {
        for_each = resources.value.volumes != null ? resources.value.volumes : []
        content {
          name        = volumes.value.name
          volume_type = volumes.value.volume_type
          size_gb     = volumes.value.size_gb
        }
      }
    }
  }

  # Network
  dynamic "network" {
    for_each = each.value.network != null ? [each.value.network] : []
    content {
      name             = network.value.name
      subnetwork       = network.value.subnetwork
      session_affinity = network.value.session_affinity
      instance_tag     = network.value.instance_tag

      dynamic "forwarded_ports" {
        for_each = network.value.forwarded_ports != null ? network.value.forwarded_ports : []
        content {
          name = forwarded_ports.value.name
          port = forwarded_ports.value.port
        }
      }
    }
  }

  # Liveness check
  dynamic "liveness_check" {
    for_each = each.value.liveness_check != null ? [each.value.liveness_check] : []
    content {
      check_interval    = liveness_check.value.check_interval
      failure_threshold = liveness_check.value.failure_threshold
      host              = liveness_check.value.host
      initial_delay     = liveness_check.value.initial_delay
      path              = liveness_check.value.path
      success_threshold = liveness_check.value.success_threshold
      timeout           = liveness_check.value.timeout
    }
  }

  # Readiness check
  dynamic "readiness_check" {
    for_each = each.value.readiness_check != null ? [each.value.readiness_check] : []
    content {
      app_start_timeout = readiness_check.value.app_start_timeout
      check_interval    = readiness_check.value.check_interval
      failure_threshold = readiness_check.value.failure_threshold
      host              = readiness_check.value.host
      path              = readiness_check.value.path
      success_threshold = readiness_check.value.success_threshold
      timeout           = readiness_check.value.timeout
    }
  }

  # Beta settings
  beta_settings = each.value.beta_settings

  # Serving status
  serving_status = each.value.serving_status

  # Inbound services
  inbound_services = each.value.inbound_services

  # No traffic on deploy
  noop_on_destroy           = each.value.noop_on_destroy
  delete_service_on_destroy = each.value.delete_service_on_destroy

  depends_on = [google_app_engine_application.app]
}
