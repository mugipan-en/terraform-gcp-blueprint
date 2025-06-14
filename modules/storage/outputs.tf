output "bucket_names" {
  description = "Names of the created Cloud Storage buckets"
  value       = { for k, v in google_storage_bucket.buckets : k => v.name }
}

output "bucket_urls" {
  description = "URLs of the created Cloud Storage buckets"
  value       = { for k, v in google_storage_bucket.buckets : k => v.url }
}

output "bucket_self_links" {
  description = "Self links of the created Cloud Storage buckets"
  value       = { for k, v in google_storage_bucket.buckets : k => v.self_link }
}

output "bucket_locations" {
  description = "Locations of the created Cloud Storage buckets"
  value       = { for k, v in google_storage_bucket.buckets : k => v.location }
}

output "bucket_storage_classes" {
  description = "Storage classes of the created Cloud Storage buckets"
  value       = { for k, v in google_storage_bucket.buckets : k => v.storage_class }
}

output "bucket_lifecycle_rules" {
  description = "Lifecycle rules of the created Cloud Storage buckets"
  value       = { for k, v in google_storage_bucket.buckets : k => v.lifecycle_rule }
}

output "bucket_versioning" {
  description = "Versioning configuration of the created Cloud Storage buckets"
  value       = { for k, v in google_storage_bucket.buckets : k => v.versioning }
}

output "bucket_encryption" {
  description = "Encryption configuration of the created Cloud Storage buckets"
  value       = { for k, v in google_storage_bucket.buckets : k => v.encryption }
}

output "bucket_cors" {
  description = "CORS configuration of the created Cloud Storage buckets"
  value       = { for k, v in google_storage_bucket.buckets : k => v.cors }
}

output "bucket_website" {
  description = "Website configuration of the created Cloud Storage buckets"
  value       = { for k, v in google_storage_bucket.buckets : k => v.website }
}

output "bucket_retention_policy" {
  description = "Retention policy of the created Cloud Storage buckets"
  value       = { for k, v in google_storage_bucket.buckets : k => v.retention_policy }
}

output "bucket_logging" {
  description = "Logging configuration of the created Cloud Storage buckets"
  value       = { for k, v in google_storage_bucket.buckets : k => v.logging }
}

output "bucket_notification" {
  description = "Notification configuration of the created Cloud Storage buckets"
  value       = { for k, v in google_storage_bucket.buckets : k => v.notification }
}

output "bucket_labels" {
  description = "Labels of the created Cloud Storage buckets"
  value       = { for k, v in google_storage_bucket.buckets : k => v.labels }
}

output "default_objects" {
  description = "Information about default objects created in buckets"
  value = {
    for k, v in google_storage_bucket_object.default_objects : k => {
      name         = v.name
      bucket       = v.bucket
      content_type = v.content_type
      size         = v.size
      md5hash      = v.md5hash
      crc32c       = v.crc32c
      etag         = v.etag
      generation   = v.generation
      self_link    = v.self_link
      media_link   = v.media_link
    }
  }
}

output "transfer_jobs" {
  description = "Information about Cloud Storage Transfer Service jobs"
  value = {
    for k, v in google_storage_transfer_job.transfer_jobs : k => {
      name                   = v.name
      description            = v.description
      status                 = v.status
      creation_time          = v.creation_time
      last_modification_time = v.last_modification_time
    }
  }
}

# Useful outputs for applications
output "primary_bucket_name" {
  description = "Name of the primary/main bucket"
  value       = try(google_storage_bucket.buckets["main"].name, null)
}

output "primary_bucket_url" {
  description = "URL of the primary/main bucket"
  value       = try(google_storage_bucket.buckets["main"].url, null)
}

output "backup_bucket_name" {
  description = "Name of the backup bucket"
  value       = try(google_storage_bucket.buckets["backup"].name, null)
}

output "static_assets_bucket_name" {
  description = "Name of the static assets bucket"
  value       = try(google_storage_bucket.buckets["static-assets"].name, null)
}

output "logs_bucket_name" {
  description = "Name of the logs bucket"
  value       = try(google_storage_bucket.buckets["logs"].name, null)
}

# Security and access information
output "bucket_iam_bindings" {
  description = "IAM bindings for buckets"
  value = {
    for k, v in google_storage_bucket_iam_binding.bucket_bindings : k => {
      bucket  = v.bucket
      role    = v.role
      members = v.members
    }
  }
}

# Usage examples for applications
output "usage_examples" {
  description = "Usage examples for accessing the buckets"
  value = {
    gsutil_commands = {
      for k, v in google_storage_bucket.buckets : k => {
        list_objects = "gsutil ls gs://${v.name}/"
        copy_file    = "gsutil cp /local/file gs://${v.name}/path/"
        sync_folder  = "gsutil -m rsync -r /local/folder gs://${v.name}/folder/"
      }
    }

    python_client = {
      for k, v in google_storage_bucket.buckets : k => {
        bucket_name    = v.name
        upload_example = "from google.cloud import storage; client = storage.Client(); bucket = client.bucket('${v.name}'); blob = bucket.blob('filename'); blob.upload_from_filename('/path/to/file')"
      }
    }

    api_endpoints = {
      for k, v in google_storage_bucket.buckets : k => {
        json_api = "https://storage.googleapis.com/storage/v1/b/${v.name}/o"
        xml_api  = "https://${v.name}.storage.googleapis.com/"
      }
    }
  }
}
