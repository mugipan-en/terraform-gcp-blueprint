# Cloud Build Module
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Cloud Build Triggers
resource "google_cloudbuild_trigger" "triggers" {
  for_each = var.build_triggers

  project     = var.project_id
  name        = "${var.name_prefix}-${each.key}"
  description = each.value.description
  disabled    = each.value.disabled
  tags        = each.value.tags

  dynamic "github" {
    for_each = each.value.github != null ? [each.value.github] : []
    content {
      owner = github.value.owner
      name  = github.value.name
      
      dynamic "push" {
        for_each = github.value.push != null ? [github.value.push] : []
        content {
          branch          = push.value.branch
          tag             = push.value.tag
          invert_regex    = push.value.invert_regex
        }
      }
      
      dynamic "pull_request" {
        for_each = github.value.pull_request != null ? [github.value.pull_request] : []
        content {
          branch          = pull_request.value.branch
          comment_control = pull_request.value.comment_control
          invert_regex    = pull_request.value.invert_regex
        }
      }
    }
  }

  dynamic "trigger_template" {
    for_each = each.value.trigger_template != null ? [each.value.trigger_template] : []
    content {
      project_id   = trigger_template.value.project_id
      repo_name    = trigger_template.value.repo_name
      branch_name  = trigger_template.value.branch_name
      tag_name     = trigger_template.value.tag_name
      commit_sha   = trigger_template.value.commit_sha
      dir          = trigger_template.value.dir
      invert_regex = trigger_template.value.invert_regex
    }
  }

  dynamic "build" {
    for_each = each.value.build_config != null ? [each.value.build_config] : []
    content {
      dynamic "step" {
        for_each = build.value.steps
        content {
          name       = step.value.name
          args       = step.value.args
          env        = step.value.env
          id         = step.value.id
          entrypoint = step.value.entrypoint
          dir        = step.value.dir
          secret_env = step.value.secret_env
          timeout    = step.value.timeout
          timing     = step.value.timing
          wait_for   = step.value.wait_for
        }
      }
      
      timeout = build.value.timeout
      images  = build.value.images
      substitutions = build.value.substitutions
      
      dynamic "artifacts" {
        for_each = build.value.artifacts != null ? [build.value.artifacts] : []
        content {
          images = artifacts.value.images
          
          dynamic "objects" {
            for_each = artifacts.value.objects != null ? [artifacts.value.objects] : []
            content {
              location = objects.value.location
              paths    = objects.value.paths
            }
          }
        }
      }
      
      dynamic "options" {
        for_each = build.value.options != null ? [build.value.options] : []
        content {
          disk_size_gb                = options.value.disk_size_gb
          dynamic_substitutions       = options.value.dynamic_substitutions
          env                        = options.value.env
          log_streaming_option       = options.value.log_streaming_option
          logging                    = options.value.logging
          machine_type               = options.value.machine_type
          requested_verify_option    = options.value.requested_verify_option
          secret_env                 = options.value.secret_env
          source_provenance_hash     = options.value.source_provenance_hash
          substitution_option        = options.value.substitution_option
          worker_pool                = options.value.worker_pool
        }
      }
    }
  }

  filename = each.value.filename
  
  dynamic "substitutions" {
    for_each = each.value.substitutions != null ? [each.value.substitutions] : []
    content {
      substitutions.value
    }
  }

  service_account = each.value.service_account
}