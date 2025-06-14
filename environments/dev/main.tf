terraform {
  required_version = ">= 1.5"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.0"
    }
  }
  
  backend "gcs" {
    bucket = "your-terraform-state-bucket"
    prefix = "environments/dev"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Local values for common tags and naming
locals {
  common_tags = merge(var.tags, {
    Environment = "development"
    ManagedBy   = "terraform"
  })
  
  name_prefix = "${var.project_name}-dev"
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"
  
  project_id   = var.project_id
  region       = var.region
  name_prefix  = local.name_prefix
  
  vpc_name     = var.vpc_name
  subnet_cidrs = var.subnet_cidrs
  
  tags = local.common_tags
}

# GKE Module
module "gke" {
  source = "../../modules/gke"
  
  project_id      = var.project_id
  region          = var.region
  zone_or_region  = var.region
  name_prefix     = local.name_prefix
  
  cluster_name           = var.gke_cluster_name
  initial_node_count     = var.gke_node_count
  min_node_count         = var.gke_node_count
  max_node_count         = var.gke_node_count * 2
  machine_type           = var.gke_machine_type
  disk_size_gb           = var.gke_disk_size_gb
  
  network              = module.vpc.network_name
  subnetwork           = module.vpc.public_subnet_name
  pods_range_name      = module.vpc.pods_range_name
  services_range_name  = module.vpc.services_range_name
  
  tags = local.common_tags
  
  depends_on = [module.vpc]
}

# Cloud SQL Module
module "cloud_sql" {
  source = "../../modules/cloud-sql"
  
  project_id   = var.project_id
  region       = var.region
  name_prefix  = local.name_prefix
  
  database_name    = var.db_name
  instance_type    = var.db_instance_type
  database_version = var.db_version
  
  network = module.vpc.network_id
  
  tags = local.common_tags
  
  depends_on = [module.vpc]
}

# Cloud Storage Module
module "storage" {
  source = "../../modules/storage"
  
  project_id  = var.project_id
  region      = var.region
  name_prefix = local.name_prefix
  
  bucket_configs = {
    main = {
      location                     = var.region
      storage_class               = "STANDARD"
      force_destroy               = true  # for dev environment
      uniform_bucket_level_access = true
      public_access_prevention    = "enforced"
      versioning_enabled          = false  # for dev environment
      kms_key_name               = null
      access_logs_bucket         = null
      access_logs_prefix         = null
      labels                     = {}
      lifecycle_rules            = []
      cors_config                = null
      website_config             = null
      retention_policy           = null
      notification_configs       = []
    }
  }
  
  tags = local.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"
  
  project_id  = var.project_id
  region      = var.region
  name_prefix = local.name_prefix
  
  # Basic monitoring for dev environment
  email_notification_channels = {
    default = {
      display_name  = "Default Email"
      email_address = "admin@example.com"
      enabled       = true
    }
  }
  
  tags = local.common_tags
}

# Security Module
module "security" {
  source = "../../modules/security"
  
  project_id  = var.project_id
  region      = var.region
  name_prefix = local.name_prefix
  
  service_accounts = {
    app = {
      display_name = "Application Service Account"
      description  = "Service account for application workloads"
      roles        = ["roles/storage.objectViewer"]
    }
  }
  
  tags = local.common_tags
}