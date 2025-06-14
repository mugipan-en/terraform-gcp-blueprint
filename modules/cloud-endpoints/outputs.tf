# Endpoints Services
output "endpoints_services" {
  description = "Endpoints service information"
  value = {
    for k, v in google_endpoints_service.endpoints_services : k => {
      id           = v.id
      service_name = v.service_name
      project      = v.project
      config_id    = v.config_id
      dns_address  = v.dns_address
      endpoints    = v.endpoints
      apis         = v.apis
    }
  }
}

# Service URLs
output "service_urls" {
  description = "Endpoints service URLs"
  value = {
    for k, v in google_endpoints_service.endpoints_services : k => {
      service_url = "https://${v.service_name}"
      dns_address = v.dns_address
      endpoints   = v.endpoints
    }
  }
}

# API Configuration
output "api_configs" {
  description = "API configuration information"
  value = {
    for k, v in google_endpoints_service.endpoints_services : k => {
      config_id = v.config_id
      apis = [
        for api in v.apis : {
          name    = api.name
          version = api.version
          syntax  = api.syntax
          methods = api.methods
        }
      ]
    }
  }
}

# Summary
output "endpoints_summary" {
  description = "Summary of Endpoints deployment"
  value = {
    total_services = length(google_endpoints_service.endpoints_services)

    services = {
      for k, v in google_endpoints_service.endpoints_services : k => {
        name           = v.service_name
        config_id      = v.config_id
        dns_address    = v.dns_address
        api_count      = length(v.apis)
        endpoint_count = length(v.endpoints)
      }
    }

    service_types = {
      openapi_services = length([
        for k, v in var.endpoints_services : k
        if v.openapi_config != null
      ])
      grpc_services = length([
        for k, v in var.endpoints_services : k
        if v.grpc_config != null
      ])
    }
  }
}
