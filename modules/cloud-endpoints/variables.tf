variable "project_id" {
  description = "The project ID to deploy resources into"
  type        = string
}

# Endpoints Services
variable "endpoints_services" {
  description = "Endpoints service configurations"
  type = map(object({
    service_name = string
    
    # OpenAPI configuration (for REST APIs)
    openapi_config = optional(string)
    
    # gRPC configuration
    grpc_config    = optional(string)
    protoc_output  = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.endpoints_services :
      (v.openapi_config != null && v.grpc_config == null && v.protoc_output == null) ||
      (v.openapi_config == null && v.grpc_config != null && v.protoc_output != null) ||
      (v.openapi_config == null && v.grpc_config == null && v.protoc_output == null)
    ])
    error_message = "Each service must have either openapi_config OR both grpc_config and protoc_output, but not both types."
  }
}

# Service IAM Bindings
variable "service_iam_bindings" {
  description = "IAM bindings for Endpoints services"
  type = map(object({
    service_key = string
    role        = string
    members     = list(string)
    
    condition = optional(object({
      title       = string
      description = optional(string)
      expression  = string
    }))
  }))
  default = {}
}

# Service IAM Members
variable "service_iam_members" {
  description = "IAM members for Endpoints services"
  type = map(object({
    service_key = string
    role        = string
    member      = string
    
    condition = optional(object({
      title       = string
      description = optional(string)
      expression  = string
    }))
  }))
  default = {}
}

# Consumer IAM Bindings
variable "consumer_iam_bindings" {
  description = "IAM bindings for Endpoints service consumers"
  type = map(object({
    service_key      = string
    consumer_project = string
    role            = string
    members         = list(string)
    
    condition = optional(object({
      title       = string
      description = optional(string)
      expression  = string
    }))
  }))
  default = {}
}

# Consumer IAM Members
variable "consumer_iam_members" {
  description = "IAM members for Endpoints service consumers"
  type = map(object({
    service_key      = string
    consumer_project = string
    role            = string
    member          = string
    
    condition = optional(object({
      title       = string
      description = optional(string)
      expression  = string
    }))
  }))
  default = {}
}