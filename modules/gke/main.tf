# 🔥 GKE Module - Modern File Structure
# This is the main entry point for the GKE module
# Individual components are organized in separate files:
# - locals.tf: Local values and environment configuration
# - service-account.tf: Service account and IAM management
# - cluster.tf: GKE cluster configuration
# - node-pools.tf: Node pool configurations

terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
