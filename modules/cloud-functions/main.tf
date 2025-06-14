# Cloud Functions (Gen 2)
resource "google_cloudfunctions2_function" "functions" {
  for_each = var.functions

  name     = "${var.name_prefix}-${each.key}"
  location = each.value.location

  build_config {
    runtime     = each.value.runtime
    entry_point = each.value.entry_point

    dynamic "source" {
      for_each = each.value.source_archive_bucket != null ? [1] : []
      content {
        storage_source {
          bucket = each.value.source_archive_bucket
          object = each.value.source_archive_object
        }
      }
    }

    dynamic "source" {
      for_each = each.value.source_repository != null ? [each.value.source_repository] : []
      content {
        repo_source {
          project_id   = source.value.project_id
          repo_name    = source.value.repo_name
          branch_name  = source.value.branch_name
          tag_name     = source.value.tag_name
          commit_sha   = source.value.commit_sha
          dir          = source.value.dir
          invert_regex = source.value.invert_regex
        }
      }
    }

    # Environment variables for build
    environment_variables = each.value.build_environment_variables

    # Docker repository
    docker_repository = each.value.docker_repository

    # Worker pool
    worker_pool = each.value.worker_pool
  }

  service_config {
    max_instance_count               = each.value.max_instance_count
    min_instance_count               = each.value.min_instance_count
    available_memory                 = each.value.available_memory
    timeout_seconds                  = each.value.timeout_seconds
    max_instance_request_concurrency = each.value.max_instance_request_concurrency
    available_cpu                    = each.value.available_cpu
    environment_variables            = each.value.environment_variables
    ingress_settings                 = each.value.ingress_settings
    all_traffic_on_latest_revision   = each.value.all_traffic_on_latest_revision
    service_account_email            = each.value.service_account_email

    # Secret environment variables
    dynamic "secret_environment_variables" {
      for_each = each.value.secret_environment_variables
      content {
        key        = secret_environment_variables.value.key
        project_id = secret_environment_variables.value.project_id
        secret     = secret_environment_variables.value.secret
        version    = secret_environment_variables.value.version
      }
    }

    # Secret volumes
    dynamic "secret_volumes" {
      for_each = each.value.secret_volumes
      content {
        mount_path = secret_volumes.value.mount_path
        project_id = secret_volumes.value.project_id
        secret     = secret_volumes.value.secret

        dynamic "versions" {
          for_each = secret_volumes.value.versions
          content {
            version = versions.value.version
            path    = versions.value.path
          }
        }
      }
    }

    # VPC connector
    dynamic "vpc_connector" {
      for_each = each.value.vpc_connector != null ? [each.value.vpc_connector] : []
      content {
        connector       = vpc_connector.value.connector
        egress_settings = vpc_connector.value.egress_settings
      }
    }
  }

  # Event trigger
  dynamic "event_trigger" {
    for_each = each.value.event_trigger != null ? [each.value.event_trigger] : []
    content {
      trigger_region = event_trigger.value.trigger_region
      event_type     = event_trigger.value.event_type
      retry_policy   = event_trigger.value.retry_policy

      dynamic "event_filters" {
        for_each = event_trigger.value.event_filters
        content {
          attribute = event_filters.value.attribute
          value     = event_filters.value.value
          operator  = event_filters.value.operator
        }
      }

      service_account_email = event_trigger.value.service_account_email
    }
  }

  labels = merge(var.tags, each.value.labels)

  lifecycle {
    ignore_changes = [
      build_config[0].source[0].storage_source[0].generation,
    ]
  }
}

# Cloud Functions (Gen 1) - Legacy support
resource "google_cloudfunctions_function" "functions_gen1" {
  for_each = var.functions_gen1

  name        = "${var.name_prefix}-${each.key}"
  region      = each.value.region
  runtime     = each.value.runtime
  entry_point = each.value.entry_point

  # Source archive
  source_archive_bucket = each.value.source_archive_bucket
  source_archive_object = each.value.source_archive_object

  # Trigger
  dynamic "event_trigger" {
    for_each = each.value.event_trigger != null ? [each.value.event_trigger] : []
    content {
      event_type = event_trigger.value.event_type
      resource   = event_trigger.value.resource

      dynamic "failure_policy" {
        for_each = event_trigger.value.failure_policy != null ? [event_trigger.value.failure_policy] : []
        content {
          retry = failure_policy.value.retry
        }
      }
    }
  }

  # HTTP trigger
  https_trigger_security_level = each.value.https_trigger_security_level
  trigger {
    https_trigger {}
  }

  # Configuration
  available_memory_mb   = each.value.available_memory_mb
  timeout               = each.value.timeout
  environment_variables = each.value.environment_variables
  ingress_settings      = each.value.ingress_settings
  service_account_email = each.value.service_account_email
  max_instances         = each.value.max_instances

  # VPC connector
  dynamic "vpc_connector" {
    for_each = each.value.vpc_connector != null ? [each.value.vpc_connector] : []
    content {
      name            = vpc_connector.value.name
      egress_settings = vpc_connector.value.egress_settings
    }
  }

  labels = merge(var.tags, each.value.labels)
}

# IAM bindings for Cloud Functions
resource "google_cloudfunctions_function_iam_binding" "function_bindings" {
  for_each = var.function_iam_bindings

  project        = var.project_id
  region         = google_cloudfunctions_function.functions_gen1[each.value.function_key].region
  cloud_function = google_cloudfunctions_function.functions_gen1[each.value.function_key].name
  role           = each.value.role
  members        = each.value.members
}

# IAM bindings for Cloud Functions Gen 2
resource "google_cloudfunctions2_function_iam_binding" "function_gen2_bindings" {
  for_each = var.function_gen2_iam_bindings

  project  = var.project_id
  location = google_cloudfunctions2_function.functions[each.value.function_key].location
  name     = google_cloudfunctions2_function.functions[each.value.function_key].name
  role     = each.value.role
  members  = each.value.members
}

# Cloud Scheduler jobs for scheduled functions
resource "google_cloud_scheduler_job" "scheduled_jobs" {
  for_each = var.scheduled_jobs

  name      = "${var.name_prefix}-${each.key}"
  region    = each.value.region
  schedule  = each.value.schedule
  time_zone = each.value.time_zone

  dynamic "http_target" {
    for_each = each.value.http_target != null ? [each.value.http_target] : []
    content {
      http_method = http_target.value.http_method
      uri         = http_target.value.uri
      body        = base64encode(http_target.value.body)
      headers     = http_target.value.headers

      dynamic "oidc_token" {
        for_each = http_target.value.oidc_token != null ? [http_target.value.oidc_token] : []
        content {
          service_account_email = oidc_token.value.service_account_email
          audience              = oidc_token.value.audience
        }
      }

      dynamic "oauth_token" {
        for_each = http_target.value.oauth_token != null ? [http_target.value.oauth_token] : []
        content {
          service_account_email = oauth_token.value.service_account_email
          scope                 = oauth_token.value.scope
        }
      }
    }
  }

  dynamic "pubsub_target" {
    for_each = each.value.pubsub_target != null ? [each.value.pubsub_target] : []
    content {
      topic_name = pubsub_target.value.topic_name
      data       = base64encode(pubsub_target.value.data)
      attributes = pubsub_target.value.attributes
    }
  }

  dynamic "app_engine_http_target" {
    for_each = each.value.app_engine_http_target != null ? [each.value.app_engine_http_target] : []
    content {
      http_method  = app_engine_http_target.value.http_method
      relative_uri = app_engine_http_target.value.relative_uri
      body         = base64encode(app_engine_http_target.value.body)
      headers      = app_engine_http_target.value.headers

      dynamic "app_engine_routing" {
        for_each = app_engine_http_target.value.app_engine_routing != null ? [app_engine_http_target.value.app_engine_routing] : []
        content {
          service  = app_engine_routing.value.service
          version  = app_engine_routing.value.version
          instance = app_engine_routing.value.instance
        }
      }
    }
  }

  dynamic "retry_config" {
    for_each = each.value.retry_config != null ? [each.value.retry_config] : []
    content {
      retry_count          = retry_config.value.retry_count
      max_retry_duration   = retry_config.value.max_retry_duration
      min_backoff_duration = retry_config.value.min_backoff_duration
      max_backoff_duration = retry_config.value.max_backoff_duration
      max_doublings        = retry_config.value.max_doublings
    }
  }
}
