# Firestore Database
output "firestore_database" {
  description = "Firestore database information"
  value = var.create_database ? {
    id                              = google_firestore_database.database[0].id
    name                           = google_firestore_database.database[0].name
    location_id                    = google_firestore_database.database[0].location_id
    type                           = google_firestore_database.database[0].type
    concurrency_mode               = google_firestore_database.database[0].concurrency_mode
    app_engine_integration_mode    = google_firestore_database.database[0].app_engine_integration_mode
    key_prefix                     = google_firestore_database.database[0].key_prefix
    create_time                    = google_firestore_database.database[0].create_time
    update_time                    = google_firestore_database.database[0].update_time
    uid                           = google_firestore_database.database[0].uid
    etag                          = google_firestore_database.database[0].etag
  } : null
}

# Firestore Indexes
output "firestore_indexes" {
  description = "Firestore index information"
  value = {
    for k, v in google_firestore_index.indexes : k => {
      id         = v.id
      name       = v.name
      collection = v.collection
      query_scope = v.query_scope
      api_scope  = v.api_scope
      fields     = v.fields
    }
  }
}

# Security Rules
output "security_rulesets" {
  description = "Firestore security ruleset information"
  value = {
    for k, v in google_firebaserules_ruleset.firestore_rules : k => {
      id          = v.id
      name        = v.name
      create_time = v.create_time
    }
  }
}

output "security_releases" {
  description = "Firestore security rule release information"
  value = {
    for k, v in google_firebaserules_release.firestore_release : k => {
      id           = v.id
      name         = v.name
      ruleset_name = v.ruleset_name
      create_time  = v.create_time
      update_time  = v.update_time
    }
  }
}

# Database Connection Info
output "database_connection_info" {
  description = "Information for connecting to the Firestore database"
  value = var.create_database ? {
    project_id   = var.project_id
    database_id  = google_firestore_database.database[0].name
    location_id  = google_firestore_database.database[0].location_id
    
    # Connection strings for different client libraries
    connection_strings = {
      web_config = {
        projectId = var.project_id
        databaseId = google_firestore_database.database[0].name
      }
      
      admin_sdk = {
        project_id   = var.project_id
        database_id  = google_firestore_database.database[0].name
      }
      
      rest_api = {
        base_url = "https://firestore.googleapis.com/v1/projects/${var.project_id}/databases/${google_firestore_database.database[0].name}"
      }
    }
  } : null
}

# Summary
output "firestore_summary" {
  description = "Summary of Firestore deployment"
  value = {
    database_created = var.create_database
    database_name    = var.create_database ? google_firestore_database.database[0].name : var.database_id
    database_type    = var.database_type
    location_id      = var.location_id
    
    total_indexes      = length(google_firestore_index.indexes)
    total_rulesets     = length(google_firebaserules_ruleset.firestore_rules)
    
    indexes_by_collection = {
      for collection in distinct([for idx in google_firestore_index.indexes : idx.collection]) :
      collection => [
        for k, v in google_firestore_index.indexes :
        k if v.collection == collection
      ]
    }
    
    features = {
      point_in_time_recovery = var.point_in_time_recovery_enablement == "POINT_IN_TIME_RECOVERY_ENABLED"
      delete_protection      = var.delete_protection_state == "DELETE_PROTECTION_ENABLED"
      app_engine_integration = var.app_engine_integration_mode == "ENABLED"
    }
  }
}