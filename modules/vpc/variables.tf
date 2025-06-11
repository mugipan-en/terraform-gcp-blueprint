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

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "main-vpc"
}

variable "subnet_cidrs" {
  description = "CIDR blocks for subnets"
  type = object({
    public   = string
    private  = string
    pods     = string
    services = string
  })
  default = {
    public   = "10.0.1.0/24"
    private  = "10.0.2.0/24"
    pods     = "10.1.0.0/16"
    services = "10.2.0.0/16"
  }

  validation {
    condition = alltrue([
      can(cidrhost(var.subnet_cidrs.public, 0)),
      can(cidrhost(var.subnet_cidrs.private, 0)),
      can(cidrhost(var.subnet_cidrs.pods, 0)),
      can(cidrhost(var.subnet_cidrs.services, 0))
    ])
    error_message = "All subnet CIDRs must be valid CIDR blocks."
  }
}

variable "ssh_source_ranges" {
  description = "Source IP ranges that can SSH to instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}