# App Engine Application
output "app_engine_application" {
  description = "App Engine application information"
  value = var.create_application ? {
    id               = google_app_engine_application.app[0].id
    name             = google_app_engine_application.app[0].name
    location_id      = google_app_engine_application.app[0].location_id
    auth_domain      = google_app_engine_application.app[0].auth_domain
    default_hostname = google_app_engine_application.app[0].default_hostname
    default_bucket   = google_app_engine_application.app[0].default_bucket
    serving_status   = google_app_engine_application.app[0].serving_status
    database_type    = google_app_engine_application.app[0].database_type
  } : null
}

# Standard App Engine Versions
output "standard_app_versions" {
  description = "Standard App Engine version information"
  value = {
    for k, v in google_app_engine_standard_app_version.standard_versions : k => {
      id             = v.id
      name           = v.name
      service        = v.service
      version_id     = v.version_id
      runtime        = v.runtime
      instance_class = v.instance_class
      serving_status = v.serving_status
    }
  }
}

# Flexible App Engine Versions
output "flexible_app_versions" {
  description = "Flexible App Engine version information"
  value = {
    for k, v in google_app_engine_flexible_app_version.flexible_versions : k => {
      id             = v.id
      name           = v.name
      service        = v.service
      version_id     = v.version_id
      runtime        = v.runtime
      serving_status = v.serving_status
    }
  }
}

# Traffic Splits
output "traffic_splits" {
  description = "Traffic split information"
  value = {
    for k, v in google_app_engine_service_split_traffic.traffic_splits : k => {
      id      = v.id
      service = v.service
      split   = v.split
    }
  }
}

# Domain Mappings
output "domain_mappings" {
  description = "Domain mapping information"
  value = {
    for k, v in google_app_engine_domain_mapping.domain_mappings : k => {
      id                    = v.id
      domain_name          = v.domain_name
      name                 = v.name
      resource_records     = v.resource_records
      ssl_settings         = v.ssl_settings
    }
  }
}

# Managed SSL Certificates
output "managed_certificates" {
  description = "Managed SSL certificate information"
  value = {
    for k, v in google_app_engine_managed_ssl_certificate.managed_certificates : k => {
      id             = v.id
      certificate_id = v.certificate_id
      display_name   = v.display_name
      domains        = v.domains
      name           = v.name
    }
  }
}

# Firewall Rules
output "firewall_rules" {
  description = "Firewall rule information"
  value = {
    for k, v in google_app_engine_firewall_rule.firewall_rules : k => {
      priority     = v.priority
      action       = v.action
      source_range = v.source_range
      description  = v.description
    }
  }
}

# App Engine URLs
output "app_engine_urls" {
  description = "App Engine service URLs"
  value = var.create_application ? {
    default_url = "https://${google_app_engine_application.app[0].default_hostname}"
    
    service_urls = merge(
      {
        for k, v in google_app_engine_standard_app_version.standard_versions :
        "${k}-${v.version_id}" => "https://${v.version_id}-dot-${v.service}-dot-${var.project_id}.appspot.com"
      },
      {
        for k, v in google_app_engine_flexible_app_version.flexible_versions :
        "${k}-${v.version_id}" => "https://${v.version_id}-dot-${v.service}-dot-${var.project_id}.appspot.com"
      }
    )
    
    custom_domain_urls = {
      for k, v in google_app_engine_domain_mapping.domain_mappings :
      k => "https://${v.domain_name}"
    }
  } : null
}

# Summary
output "app_engine_summary" {
  description = "Summary of App Engine deployment"
  value = var.create_application ? {
    application_id       = google_app_engine_application.app[0].id
    location            = google_app_engine_application.app[0].location_id
    default_hostname    = google_app_engine_application.app[0].default_hostname
    total_standard_services  = length(google_app_engine_standard_app_version.standard_versions)
    total_flexible_services  = length(google_app_engine_flexible_app_version.flexible_versions)
    total_domain_mappings   = length(google_app_engine_domain_mapping.domain_mappings)
    total_firewall_rules    = length(google_app_engine_firewall_rule.firewall_rules)
    
    services = {
      standard = [for k, v in google_app_engine_standard_app_version.standard_versions : {
        name       = k
        service    = v.service
        version    = v.version_id
        runtime    = v.runtime
      }]
      flexible = [for k, v in google_app_engine_flexible_app_version.flexible_versions : {
        name       = k
        service    = v.service
        version    = v.version_id
        runtime    = v.runtime
      }]
    }
  } : null
}