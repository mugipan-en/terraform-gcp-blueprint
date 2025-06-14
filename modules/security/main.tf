# Service Accounts
resource "google_service_account" "service_accounts" {
  for_each = var.service_accounts

  account_id   = "${var.name_prefix}-${each.key}"
  display_name = each.value.display_name
  description  = each.value.description
}

# IAM Policy Bindings for Service Accounts
resource "google_project_iam_member" "service_account_roles" {
  for_each = local.service_account_roles

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.service_accounts[each.value.account_key].email}"
}

# Service Account Keys (if needed)
resource "google_service_account_key" "keys" {
  for_each = var.service_account_keys

  service_account_id = google_service_account.service_accounts[each.value.service_account].name
  public_key_type    = each.value.public_key_type
  private_key_type   = each.value.private_key_type
}

# Custom IAM Roles
resource "google_project_iam_custom_role" "custom_roles" {
  for_each = var.custom_roles

  role_id     = "${var.name_prefix}_${each.key}"
  title       = each.value.title
  description = each.value.description
  permissions = each.value.permissions
  stage       = each.value.stage
}

# IAM Policy Bindings
resource "google_project_iam_binding" "bindings" {
  for_each = var.iam_bindings

  project = var.project_id
  role    = each.value.role
  members = each.value.members

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# Secret Manager Secrets
resource "google_secret_manager_secret" "secrets" {
  for_each = var.secrets

  secret_id = "${var.name_prefix}-${each.key}"

  labels = merge(var.tags, each.value.labels)

  replication {
    dynamic "user_managed" {
      for_each = each.value.replication.user_managed != null ? [each.value.replication.user_managed] : []
      content {
        dynamic "replicas" {
          for_each = user_managed.value.replicas
          content {
            location = replicas.value.location
            dynamic "customer_managed_encryption" {
              for_each = replicas.value.customer_managed_encryption != null ? [replicas.value.customer_managed_encryption] : []
              content {
                kms_key_name = customer_managed_encryption.value.kms_key_name
              }
            }
          }
        }
      }
    }

    dynamic "automatic" {
      for_each = each.value.replication.automatic != null ? [each.value.replication.automatic] : []
      content {
        dynamic "customer_managed_encryption" {
          for_each = automatic.value.customer_managed_encryption != null ? [automatic.value.customer_managed_encryption] : []
          content {
            kms_key_name = customer_managed_encryption.value.kms_key_name
          }
        }
      }
    }
  }

  dynamic "rotation" {
    for_each = each.value.rotation != null ? [each.value.rotation] : []
    content {
      next_rotation_time = rotation.value.next_rotation_time
      rotation_period    = rotation.value.rotation_period
    }
  }
}

# Secret Manager Secret Versions
resource "google_secret_manager_secret_version" "secret_versions" {
  for_each = var.secret_data

  secret      = google_secret_manager_secret.secrets[each.value.secret_key].id
  secret_data = each.value.data
  enabled     = each.value.enabled
}

# Secret Manager IAM
resource "google_secret_manager_secret_iam_binding" "secret_bindings" {
  for_each = var.secret_iam_bindings

  project   = var.project_id
  secret_id = google_secret_manager_secret.secrets[each.value.secret_key].secret_id
  role      = each.value.role
  members   = each.value.members
}

# Cloud KMS Key Rings
resource "google_kms_key_ring" "key_rings" {
  for_each = var.kms_key_rings

  name     = "${var.name_prefix}-${each.key}"
  location = each.value.location
}

# Cloud KMS Crypto Keys
resource "google_kms_crypto_key" "crypto_keys" {
  for_each = var.kms_crypto_keys

  name     = each.key
  key_ring = google_kms_key_ring.key_rings[each.value.key_ring].id

  purpose         = each.value.purpose
  rotation_period = each.value.rotation_period

  dynamic "version_template" {
    for_each = each.value.version_template != null ? [each.value.version_template] : []
    content {
      algorithm        = version_template.value.algorithm
      protection_level = version_template.value.protection_level
    }
  }

  labels = merge(var.tags, each.value.labels)

  lifecycle {
    prevent_destroy = true
  }
}

# Cloud KMS IAM
resource "google_kms_crypto_key_iam_binding" "crypto_key_bindings" {
  for_each = var.kms_crypto_key_iam_bindings

  crypto_key_id = google_kms_crypto_key.crypto_keys[each.value.crypto_key].id
  role          = each.value.role
  members       = each.value.members
}

# Local values for processing service account roles
locals {
  service_account_roles = merge([
    for account_key, account_config in var.service_accounts : {
      for role in account_config.roles : "${account_key}-${role}" => {
        account_key = account_key
        role        = role
      }
    }
  ]...)
}
