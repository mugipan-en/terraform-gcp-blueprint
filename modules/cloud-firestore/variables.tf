variable "project_id" {
  description = "The project ID to deploy resources into"
  type        = string
}

variable "create_database" {
  description = "Whether to create a new Firestore database"
  type        = bool
  default     = true
}

variable "database_id" {
  description = "The ID of the Firestore database"
  type        = string
  default     = "(default)"
}

variable "location_id" {
  description = "The location of the Firestore database"
  type        = string
  default     = "nam5"
}

variable "database_type" {
  description = "The type of the Firestore database"
  type        = string
  default     = "FIRESTORE_NATIVE"

  validation {
    condition     = contains(["FIRESTORE_NATIVE", "DATASTORE_MODE"], var.database_type)
    error_message = "Database type must be either FIRESTORE_NATIVE or DATASTORE_MODE."
  }
}

variable "concurrency_mode" {
  description = "The concurrency control mode to use for this database"
  type        = string
  default     = "OPTIMISTIC"

  validation {
    condition     = contains(["OPTIMISTIC", "PESSIMISTIC"], var.concurrency_mode)
    error_message = "Concurrency mode must be either OPTIMISTIC or PESSIMISTIC."
  }
}

variable "app_engine_integration_mode" {
  description = "The App Engine integration mode to use for this database"
  type        = string
  default     = "DISABLED"

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.app_engine_integration_mode)
    error_message = "App Engine integration mode must be either ENABLED or DISABLED."
  }
}

variable "point_in_time_recovery_enablement" {
  description = "Whether to enable the PITR feature on this database"
  type        = string
  default     = "POINT_IN_TIME_RECOVERY_DISABLED"

  validation {
    condition = contains([
      "POINT_IN_TIME_RECOVERY_ENABLED",
      "POINT_IN_TIME_RECOVERY_DISABLED"
    ], var.point_in_time_recovery_enablement)
    error_message = "Point-in-time recovery must be either POINT_IN_TIME_RECOVERY_ENABLED or POINT_IN_TIME_RECOVERY_DISABLED."
  }
}

variable "delete_protection_state" {
  description = "State of delete protection for the database"
  type        = string
  default     = "DELETE_PROTECTION_DISABLED"

  validation {
    condition = contains([
      "DELETE_PROTECTION_STATE_UNSPECIFIED",
      "DELETE_PROTECTION_ENABLED",
      "DELETE_PROTECTION_DISABLED"
    ], var.delete_protection_state)
    error_message = "Delete protection state must be one of the valid values."
  }
}

# Firestore Indexes
variable "firestore_indexes" {
  description = "Firestore index configurations"
  type = map(object({
    collection = string

    fields = list(object({
      field_path   = string
      order        = optional(string, "ASCENDING")
      array_config = optional(string)
    }))

    query_scope = optional(string, "COLLECTION")
    api_scope   = optional(string, "ANY_API")
  }))
  default = {}
}

# Security Rules
variable "security_rulesets" {
  description = "Firestore security rules configurations"
  type = map(object({
    rules_content = string
  }))
  default = {}
}
