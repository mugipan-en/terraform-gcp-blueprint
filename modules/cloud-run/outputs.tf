output "services" {
  description = "Cloud Run services information"
  value = {
    for k, v in google_cloud_run_service.services : k => {
      name     = v.name
      location = v.location
      id       = v.id
      url      = v.status[0].url

      traffic    = v.status[0].traffic
      conditions = v.status[0].conditions

      latest_created_revision_name = v.status[0].latest_created_revision_name
      latest_ready_revision_name   = v.status[0].latest_ready_revision_name
      observed_generation          = v.status[0].observed_generation
    }
  }
}

output "service_urls" {
  description = "URLs of Cloud Run services"
  value = {
    for k, v in google_cloud_run_service.services : k => v.status[0].url
  }
}

output "service_names" {
  description = "Names of Cloud Run services"
  value = {
    for k, v in google_cloud_run_service.services : k => v.name
  }
}

output "service_locations" {
  description = "Locations of Cloud Run services"
  value = {
    for k, v in google_cloud_run_service.services : k => v.location
  }
}

output "domain_mappings" {
  description = "Domain mappings information"
  value = {
    for k, v in google_cloud_run_domain_mapping.domain_mappings : k => {
      name     = v.name
      location = v.location
      status   = v.status
    }
  }
}

output "vpc_connectors" {
  description = "VPC connectors information"
  value = {
    for k, v in google_vpc_access_connector.connector : k => {
      name               = v.name
      ip_cidr_range      = v.ip_cidr_range
      state              = v.state
      min_throughput     = v.min_throughput
      max_throughput     = v.max_throughput
      connected_projects = v.connected_projects
    }
  }
}

# Useful outputs for integration
output "service_account_emails" {
  description = "Service account emails used by services"
  value = {
    for k, v in var.services : k => v.service_account_email
  }
}

output "curl_commands" {
  description = "Example curl commands to test the services"
  value = {
    for k, v in google_cloud_run_service.services : k => "curl -H \"Authorization: Bearer $(gcloud auth print-access-token)\" ${v.status[0].url}"
  }
}
