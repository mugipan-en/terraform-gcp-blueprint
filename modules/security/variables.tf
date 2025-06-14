variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "service_accounts" {
  description = "Service accounts to create"
  type = map(object({
    display_name = string
    description  = string
    roles        = list(string)
  }))
  default = {}
}

variable "service_account_keys" {
  description = "Service account keys to create"
  type = map(object({
    service_account  = string
    public_key_type  = string
    private_key_type = string
  }))
  default = {}
}

variable "custom_roles" {
  description = "Custom IAM roles to create"
  type = map(object({
    title       = string
    description = string
    permissions = list(string)
    stage       = string
  }))
  default = {}
}

variable "iam_bindings" {
  description = "IAM policy bindings"
  type = map(object({
    role    = string
    members = list(string)
    condition = object({
      title       = string
      description = string
      expression  = string
    })
  }))
  default = {}
}

variable "secrets" {
  description = "Secret Manager secrets"
  type = map(object({
    labels = map(string)
    replication = object({
      automatic = object({
        customer_managed_encryption = object({
          kms_key_name = string
        })
      })
      user_managed = object({
        replicas = list(object({
          location = string
          customer_managed_encryption = object({
            kms_key_name = string
          })
        }))
      })
    })
    rotation = object({
      next_rotation_time = string
      rotation_period    = string
    })
  }))
  default = {}
}

variable "secret_data" {
  description = "Secret data"
  type = map(object({
    secret_key = string
    data       = string
    enabled    = bool
  }))
  default   = {}
  sensitive = true
}

variable "secret_iam_bindings" {
  description = "Secret Manager IAM bindings"
  type = map(object({
    secret_key = string
    role       = string
    members    = list(string)
  }))
  default = {}
}

variable "kms_key_rings" {
  description = "KMS key rings"
  type = map(object({
    location = string
  }))
  default = {}
}

variable "kms_crypto_keys" {
  description = "KMS crypto keys"
  type = map(object({
    key_ring        = string
    purpose         = string
    rotation_period = string
    labels          = map(string)
    version_template = object({
      algorithm        = string
      protection_level = string
    })
  }))
  default = {}
}

variable "kms_crypto_key_iam_bindings" {
  description = "KMS crypto key IAM bindings"
  type = map(object({
    crypto_key = string
    role       = string
    members    = list(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
