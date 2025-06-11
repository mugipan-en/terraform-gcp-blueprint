variable "project_id" {
  description = "The project ID to deploy resources into"
  type        = string
}

variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
}

# Task Queues
variable "task_queues" {
  description = "Cloud Tasks queue configurations"
  type = map(object({
    location = string
    
    # Rate limits
    rate_limits = optional(object({
      max_dispatches_per_second = optional(number, 500)
      max_burst_size           = optional(number, 100)
      max_concurrent_dispatches = optional(number, 1000)
    }))
    
    # Retry configuration
    retry_config = optional(object({
      max_attempts       = optional(number, 100)
      max_retry_duration = optional(string, "3600s")
      max_backoff       = optional(string, "3600s")
      min_backoff       = optional(string, "0.100s")
      max_doublings     = optional(number, 16)
    }))
    
    # Stackdriver logging
    stackdriver_logging_config = optional(object({
      sampling_ratio = number
    }))
    
    # App Engine routing override
    app_engine_routing_override = optional(object({
      service  = optional(string)
      version  = optional(string)
      instance = optional(string)
    }))
  }))
  default = {}
}