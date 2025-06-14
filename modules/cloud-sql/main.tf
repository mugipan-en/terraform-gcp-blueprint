# 🔥 Cloud SQL Module - Modern File Structure
# This is the main entry point for the Cloud SQL module
# Individual components are organized in separate files:
# - locals.tf: Local values and environment configuration
# - instance.tf: Cloud SQL instance and read replicas
# - databases.tf: Database and user management
# - secrets.tf: Secret Manager integration

terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}
