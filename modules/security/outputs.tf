output "service_accounts" {
  description = "Created service accounts"
  value = {
    for k, v in google_service_account.service_accounts : k => {
      name         = v.name
      email        = v.email
      display_name = v.display_name
      unique_id    = v.unique_id
    }
  }
}

output "service_account_keys" {
  description = "Service account keys"
  value = {
    for k, v in google_service_account_key.keys : k => {
      name            = v.name
      public_key      = v.public_key
      public_key_type = v.public_key_type
    }
  }
  sensitive = true
}

output "custom_roles" {
  description = "Custom IAM roles"
  value = {
    for k, v in google_project_iam_custom_role.custom_roles : k => {
      id          = v.id
      name        = v.name
      title       = v.title
      permissions = v.permissions
    }
  }
}

output "secrets" {
  description = "Secret Manager secrets"
  value = {
    for k, v in google_secret_manager_secret.secrets : k => {
      id        = v.id
      secret_id = v.secret_id
      name      = v.name
    }
  }
}

output "kms_key_rings" {
  description = "KMS key rings"
  value = {
    for k, v in google_kms_key_ring.key_rings : k => {
      id       = v.id
      name     = v.name
      location = v.location
    }
  }
}

output "kms_crypto_keys" {
  description = "KMS crypto keys"
  value = {
    for k, v in google_kms_crypto_key.crypto_keys : k => {
      id       = v.id
      name     = v.name
      purpose  = v.purpose
      key_ring = v.key_ring
    }
  }
}
