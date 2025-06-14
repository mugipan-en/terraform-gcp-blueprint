# Artifact Registry Module
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Artifact Registry Repository
resource "google_artifact_registry_repository" "repositories" {
  for_each = var.repositories

  project       = var.project_id
  location      = each.value.location
  repository_id = "${var.name_prefix}-${each.key}"
  description   = each.value.description
  format        = each.value.format
  mode          = each.value.mode
  labels        = merge(var.tags, each.value.labels)

  dynamic "maven_config" {
    for_each = each.value.maven_config != null ? [each.value.maven_config] : []
    content {
      allow_snapshot_overwrites = maven_config.value.allow_snapshot_overwrites
      version_policy            = maven_config.value.version_policy
    }
  }

  dynamic "docker_config" {
    for_each = each.value.docker_config != null ? [each.value.docker_config] : []
    content {
      immutable_tags = docker_config.value.immutable_tags
    }
  }

  dynamic "remote_repository_config" {
    for_each = each.value.remote_repository_config != null ? [each.value.remote_repository_config] : []
    content {
      description = remote_repository_config.value.description

      dynamic "docker_repository" {
        for_each = remote_repository_config.value.docker_repository != null ? [remote_repository_config.value.docker_repository] : []
        content {
          public_repository = docker_repository.value.public_repository
        }
      }

      dynamic "maven_repository" {
        for_each = remote_repository_config.value.maven_repository != null ? [remote_repository_config.value.maven_repository] : []
        content {
          public_repository = maven_repository.value.public_repository
        }
      }

      dynamic "npm_repository" {
        for_each = remote_repository_config.value.npm_repository != null ? [remote_repository_config.value.npm_repository] : []
        content {
          public_repository = npm_repository.value.public_repository
        }
      }

      dynamic "python_repository" {
        for_each = remote_repository_config.value.python_repository != null ? [remote_repository_config.value.python_repository] : []
        content {
          public_repository = python_repository.value.public_repository
        }
      }

      dynamic "apt_repository" {
        for_each = remote_repository_config.value.apt_repository != null ? [remote_repository_config.value.apt_repository] : []
        content {
          public_repository {
            repository_base = apt_repository.value.public_repository.repository_base
            repository_path = apt_repository.value.public_repository.repository_path
          }
        }
      }

      dynamic "yum_repository" {
        for_each = remote_repository_config.value.yum_repository != null ? [remote_repository_config.value.yum_repository] : []
        content {
          public_repository {
            repository_base = yum_repository.value.public_repository.repository_base
            repository_path = yum_repository.value.public_repository.repository_path
          }
        }
      }
    }
  }

  dynamic "virtual_repository_config" {
    for_each = each.value.virtual_repository_config != null ? [each.value.virtual_repository_config] : []
    content {
      dynamic "upstream_policies" {
        for_each = virtual_repository_config.value.upstream_policies
        content {
          id         = upstream_policies.value.id
          repository = upstream_policies.value.repository
          priority   = upstream_policies.value.priority
        }
      }
    }
  }

  kms_key_name = each.value.kms_key_name
}
