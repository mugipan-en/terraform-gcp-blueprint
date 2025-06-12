# 🔥 Global Environment Configuration
# Common environment-aware settings that can be used across all modules

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

locals {
  # Global environment-based configuration
  global_environment_config = {
    dev = {
      # Cost optimization settings
      use_preemptible_instances = true
      enable_deletion_protection = false
      backup_retention_days     = 7
      log_retention_days       = 30
      
      # Performance settings
      enable_monitoring        = true
      enable_detailed_logging  = false
      enable_autoscaling      = true
      
      # Security settings
      require_ssl             = false
      enable_network_policy   = false
      allow_public_access     = true
    }
    
    staging = {
      # Balanced settings for staging
      use_preemptible_instances = false
      enable_deletion_protection = true
      backup_retention_days     = 14
      log_retention_days       = 60
      
      # Performance settings
      enable_monitoring        = true
      enable_detailed_logging  = true
      enable_autoscaling      = true
      
      # Security settings
      require_ssl             = true
      enable_network_policy   = true
      allow_public_access     = false
    }
    
    production = {
      # Production-grade settings
      use_preemptible_instances = false
      enable_deletion_protection = true
      backup_retention_days     = 30
      log_retention_days       = 90
      
      # Performance settings
      enable_monitoring        = true
      enable_detailed_logging  = true
      enable_autoscaling      = true
      
      # Security settings
      require_ssl             = true
      enable_network_policy   = true
      allow_public_access     = false
    }
  }
  
  # Current environment configuration
  current_env_config = local.global_environment_config[var.environment]
  
  # Common resource sizing based on environment
  resource_sizing = {
    dev = {
      small  = { cpu = "0.5", memory = "512Mi" }
      medium = { cpu = "1",   memory = "1Gi" }
      large  = { cpu = "2",   memory = "2Gi" }
    }
    staging = {
      small  = { cpu = "1",   memory = "1Gi" }
      medium = { cpu = "2",   memory = "2Gi" }
      large  = { cpu = "4",   memory = "4Gi" }
    }
    production = {
      small  = { cpu = "2",   memory = "2Gi" }
      medium = { cpu = "4",   memory = "4Gi" }
      large  = { cpu = "8",   memory = "8Gi" }
    }
  }
  
  # Network configuration per environment
  network_config = {
    dev = {
      vpc_cidr         = "10.0.0.0/16"
      public_subnet    = "10.0.1.0/24"
      private_subnet   = "10.0.2.0/24"
      pods_cidr        = "10.1.0.0/16"
      services_cidr    = "10.2.0.0/16"
      enable_nat       = true
      enable_flow_logs = false
    }
    staging = {
      vpc_cidr         = "10.10.0.0/16"
      public_subnet    = "10.10.1.0/24"
      private_subnet   = "10.10.2.0/24"
      pods_cidr        = "10.11.0.0/16"
      services_cidr    = "10.12.0.0/16"
      enable_nat       = true
      enable_flow_logs = true
    }
    production = {
      vpc_cidr         = "10.20.0.0/16"
      public_subnet    = "10.20.1.0/24"
      private_subnet   = "10.20.2.0/24"
      pods_cidr        = "10.21.0.0/16"
      services_cidr    = "10.22.0.0/16"
      enable_nat       = true
      enable_flow_logs = true
    }
  }
  
  # Common labels/tags for all resources
  common_labels = {
    environment = var.environment
    managed_by  = "terraform"
    project     = "gcp-blueprint"
  }
}

# Output the environment configuration for use in other modules
output "environment_config" {
  description = "Current environment configuration"
  value       = local.current_env_config
}

output "resource_sizing" {
  description = "Resource sizing configuration for current environment"
  value       = local.resource_sizing[var.environment]
}

output "network_config" {
  description = "Network configuration for current environment"
  value       = local.network_config[var.environment]
}

output "common_labels" {
  description = "Common labels to be applied to all resources"
  value       = local.common_labels
}