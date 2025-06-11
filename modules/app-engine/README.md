# App Engine Terraform Module

This module creates and manages Google App Engine applications with comprehensive support for both Standard and Flexible environments.

## Features

- 🚀 **App Engine Application**: Complete application setup with IAP integration
- 📦 **Standard Environment**: Python, Node.js, Java, Go, PHP runtime support
- 🐳 **Flexible Environment**: Custom containers and advanced scaling
- 🔀 **Traffic Splitting**: Blue/Green deployments and A/B testing
- 🌐 **Custom Domains**: SSL certificates and domain mapping
- 🛡️ **Firewall Rules**: IP-based access control
- 📊 **Comprehensive Monitoring**: Built-in metrics and logging

## Module Structure

```
modules/app-engine/
├── main.tf              # App Engine application and provider setup
├── services.tf          # Standard and Flexible services/versions
├── traffic.tf           # Traffic splitting configuration
├── domains.tf           # Domain mappings and SSL certificates
├── firewall.tf          # Firewall rules
├── variables.tf         # Input variable definitions
├── outputs.tf           # Output value definitions
└── README.md           # This documentation
```

## Usage

### Basic Standard Environment

```hcl
module "app_engine" {
  source = "./modules/app-engine"

  project_id  = "my-project-id"
  location_id = "us-central"

  standard_services = {
    web = {
      service_name = "default"
      version_id   = "v1"
      runtime      = "python39"
      
      deployment = {
        zip = {
          source_url = "gs://my-bucket/app.zip"
        }
      }
      
      automatic_scaling = {
        max_instances = 10
        min_instances = 1
      }
    }
  }
}
```

### Flexible Environment with Custom Container

```hcl
module "app_engine" {
  source = "./modules/app-engine"

  project_id  = "my-project-id"
  location_id = "us-central"

  flexible_services = {
    api = {
      service_name = "api"
      version_id   = "v1"
      runtime      = "custom"
      
      deployment = {
        container = {
          image = "gcr.io/my-project/my-app:latest"
        }
      }
      
      automatic_scaling = {
        min_total_instances = 1
        max_total_instances = 10
        cpu_utilization = {
          target_utilization = 0.6
        }
      }
      
      resources = {
        cpu       = 1
        memory_gb = 2
        disk_gb   = 10
      }
    }
  }
}
```

### Traffic Splitting for Blue/Green Deployment

```hcl
module "app_engine" {
  source = "./modules/app-engine"

  project_id = "my-project-id"

  standard_services = {
    web_v1 = {
      service_name = "default"
      version_id   = "v1"
      runtime      = "python39"
      # ... deployment config
    }
    web_v2 = {
      service_name = "default"
      version_id   = "v2"
      runtime      = "python39"
      # ... deployment config
    }
  }

  traffic_splits = {
    default_split = {
      service = "default"
      split = {
        allocations = {
          "v1" = "0.9"  # 90% to v1
          "v2" = "0.1"  # 10% to v2
        }
      }
    }
  }
}
```

### Custom Domain with SSL

```hcl
module "app_engine" {
  source = "./modules/app-engine"

  project_id = "my-project-id"

  domain_mappings = {
    main_domain = {
      domain_name = "example.com"
      ssl_settings = {
        ssl_management_type = "AUTOMATIC"
      }
    }
  }

  managed_certificates = {
    main_cert = {
      display_name = "Main Certificate"
      domains      = ["example.com", "www.example.com"]
    }
  }
}
```

## Importing Existing Resources

If you have existing App Engine resources, you need to import them into Terraform state:

### 1. Import App Engine Application

```bash
# Check if App Engine application exists
gcloud app describe --project=YOUR_PROJECT_ID

# Import the application
terraform import 'module.app_engine.google_app_engine_application.app[0]' YOUR_PROJECT_ID
```

### 2. Import App Engine Services/Versions

```bash
# List existing services and versions
gcloud app services list --project=YOUR_PROJECT_ID
gcloud app versions list --service=SERVICE_NAME --project=YOUR_PROJECT_ID

# Import Standard App Engine version
terraform import 'module.app_engine.google_app_engine_standard_app_version.standard_versions["SERVICE_KEY"]' "apps/YOUR_PROJECT_ID/services/SERVICE_NAME/versions/VERSION_ID"

# Import Flexible App Engine version
terraform import 'module.app_engine.google_app_engine_flexible_app_version.flexible_versions["SERVICE_KEY"]' "apps/YOUR_PROJECT_ID/services/SERVICE_NAME/versions/VERSION_ID"
```

### 3. Import Traffic Allocations

```bash
# Check current traffic allocation
gcloud app services describe SERVICE_NAME --project=YOUR_PROJECT_ID

# Import traffic split
terraform import 'module.app_engine.google_app_engine_service_split_traffic.traffic_splits["SPLIT_KEY"]' "apps/YOUR_PROJECT_ID/services/SERVICE_NAME"
```

### 4. Import Domain Mappings

```bash
# List domain mappings
gcloud app domain-mappings list --project=YOUR_PROJECT_ID

# Import domain mapping
terraform import 'module.app_engine.google_app_engine_domain_mapping.domain_mappings["DOMAIN_KEY"]' "apps/YOUR_PROJECT_ID/domainMappings/DOMAIN_NAME"
```

### 5. Import SSL Certificates

```bash
# List SSL certificates
gcloud app ssl-certificates list --project=YOUR_PROJECT_ID

# Import managed certificate
terraform import 'module.app_engine.google_app_engine_managed_ssl_certificate.managed_certificates["CERT_KEY"]' "apps/YOUR_PROJECT_ID/managedCertificates/CERTIFICATE_ID"
```

### 6. Import Firewall Rules

```bash
# List firewall rules
gcloud app firewall-rules list --project=YOUR_PROJECT_ID

# Import firewall rule
terraform import 'module.app_engine.google_app_engine_firewall_rule.firewall_rules["RULE_KEY"]' "apps/YOUR_PROJECT_ID/firewall/ingressRules/PRIORITY"
```

## Migration Strategy

### Step 1: Initial Import

1. **Backup current configuration**:
   ```bash
   gcloud app describe --project=YOUR_PROJECT_ID > app-engine-backup.yaml
   gcloud app services list --project=YOUR_PROJECT_ID > services-backup.yaml
   ```

2. **Create Terraform configuration** matching your existing resources

3. **Import resources** using the commands above

4. **Verify state**:
   ```bash
   terraform plan  # Should show no changes
   ```

### Step 2: Gradual Migration

1. **Start with traffic splitting** - Keep existing versions running
2. **Deploy new versions** with Terraform
3. **Gradually shift traffic** to Terraform-managed versions
4. **Remove old versions** once migration is complete

### Step 3: Best Practices

1. **Use version IDs** that include timestamps or commit hashes
2. **Implement proper health checks** for Flexible environment
3. **Set up monitoring** for traffic shifts
4. **Test in staging** environment first

## Important Notes

### App Engine Limitations

1. **Location cannot be changed** after application creation
2. **Application cannot be deleted** - only disabled
3. **Service names are permanent** - choose carefully
4. **Version cleanup** should be done regularly

### Terraform Considerations

1. **Use `noop_on_destroy = true`** for production versions
2. **Be careful with `delete_service_on_destroy`**
3. **App Engine application resource** should only be created once per project
4. **Import existing resources** before managing with Terraform

### Security Best Practices

1. **Use IAP** for internal applications
2. **Implement proper firewall rules**
3. **Use service accounts** with minimal permissions
4. **Enable audit logging**

## Examples

See the `examples/` directory for complete working examples:

- `examples/app-engine-standard/` - Standard environment setup
- `examples/app-engine-flexible/` - Flexible environment with containers
- `examples/app-engine-microservices/` - Multi-service architecture
- `examples/app-engine-migration/` - Migration from existing setup

## Troubleshooting

### Common Issues

1. **"Application already exists"**:
   - Set `create_application = false` if importing existing app

2. **"Version already exists"**:
   - Use unique version IDs for each deployment

3. **"Traffic allocation must sum to 1.0"**:
   - Ensure traffic split allocations add up to exactly 1.0

4. **"Domain verification failed"**:
   - Verify domain ownership in Google Search Console first

### Debug Commands

```bash
# Check App Engine status
gcloud app browse --project=YOUR_PROJECT_ID

# View logs
gcloud app logs tail --service=SERVICE_NAME --version=VERSION_ID

# Check traffic allocation
gcloud app services describe SERVICE_NAME --project=YOUR_PROJECT_ID
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | The project ID to deploy resources into | `string` | n/a | yes |
| create_application | Whether to create the App Engine application | `bool` | `true` | no |
| location_id | The location to serve the app from | `string` | `"us-central"` | no |
| standard_services | Standard App Engine services configuration | `map(object)` | `{}` | no |
| flexible_services | Flexible App Engine services configuration | `map(object)` | `{}` | no |
| traffic_splits | Traffic splitting configurations | `map(object)` | `{}` | no |
| domain_mappings | Domain mapping configurations | `map(object)` | `{}` | no |
| firewall_rules | Firewall rule configurations | `map(object)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| app_engine_application | App Engine application information |
| standard_app_versions | Standard App Engine version information |
| flexible_app_versions | Flexible App Engine version information |
| app_engine_urls | App Engine service URLs |
| app_engine_summary | Summary of App Engine deployment |