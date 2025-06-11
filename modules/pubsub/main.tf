# Pub/Sub Topics
resource "google_pubsub_topic" "topics" {
  for_each = var.topics

  name = "${var.name_prefix}-${each.key}"

  # Message retention duration
  message_retention_duration = each.value.message_retention_duration

  # Message storage policy
  dynamic "message_storage_policy" {
    for_each = each.value.message_storage_policy != null ? [each.value.message_storage_policy] : []
    content {
      allowed_persistence_regions = message_storage_policy.value.allowed_persistence_regions
    }
  }

  # Schema settings
  dynamic "schema_settings" {
    for_each = each.value.schema_settings != null ? [each.value.schema_settings] : []
    content {
      schema   = google_pubsub_schema.schemas[schema_settings.value.schema_key].id
      encoding = schema_settings.value.encoding
    }
  }

  labels = merge(var.tags, each.value.labels)
}

# Pub/Sub Subscriptions
resource "google_pubsub_subscription" "subscriptions" {
  for_each = var.subscriptions

  name  = "${var.name_prefix}-${each.key}"
  topic = google_pubsub_topic.topics[each.value.topic_key].name

  # Acknowledgment deadline
  ack_deadline_seconds = each.value.ack_deadline_seconds

  # Message retention duration
  message_retention_duration = each.value.message_retention_duration

  # Retain acknowledged messages
  retain_acked_messages = each.value.retain_acked_messages

  # Enable exactly once delivery
  enable_exactly_once_delivery = each.value.enable_exactly_once_delivery

  # Enable message ordering
  enable_message_ordering = each.value.enable_message_ordering

  # Filter
  filter = each.value.filter

  # Expiration policy
  dynamic "expiration_policy" {
    for_each = each.value.expiration_policy != null ? [each.value.expiration_policy] : []
    content {
      ttl = expiration_policy.value.ttl
    }
  }

  # Dead letter policy
  dynamic "dead_letter_policy" {
    for_each = each.value.dead_letter_policy != null ? [each.value.dead_letter_policy] : []
    content {
      dead_letter_topic     = google_pubsub_topic.topics[dead_letter_policy.value.dead_letter_topic_key].id
      max_delivery_attempts = dead_letter_policy.value.max_delivery_attempts
    }
  }

  # Retry policy
  dynamic "retry_policy" {
    for_each = each.value.retry_policy != null ? [each.value.retry_policy] : []
    content {
      minimum_backoff = retry_policy.value.minimum_backoff
      maximum_backoff = retry_policy.value.maximum_backoff
    }
  }

  # Push configuration
  dynamic "push_config" {
    for_each = each.value.push_config != null ? [each.value.push_config] : []
    content {
      push_endpoint = push_config.value.push_endpoint
      attributes    = push_config.value.attributes

      dynamic "oidc_token" {
        for_each = push_config.value.oidc_token != null ? [push_config.value.oidc_token] : []
        content {
          service_account_email = oidc_token.value.service_account_email
          audience             = oidc_token.value.audience
        }
      }

      dynamic "no_wrapper" {
        for_each = push_config.value.no_wrapper != null ? [push_config.value.no_wrapper] : []
        content {
          write_metadata = no_wrapper.value.write_metadata
        }
      }
    }
  }

  # BigQuery configuration
  dynamic "bigquery_config" {
    for_each = each.value.bigquery_config != null ? [each.value.bigquery_config] : []
    content {
      table                = bigquery_config.value.table
      use_topic_schema     = bigquery_config.value.use_topic_schema
      write_metadata       = bigquery_config.value.write_metadata
      drop_unknown_fields  = bigquery_config.value.drop_unknown_fields
    }
  }

  # Cloud Storage configuration
  dynamic "cloud_storage_config" {
    for_each = each.value.cloud_storage_config != null ? [each.value.cloud_storage_config] : []
    content {
      bucket          = cloud_storage_config.value.bucket
      filename_prefix = cloud_storage_config.value.filename_prefix
      filename_suffix = cloud_storage_config.value.filename_suffix
      max_duration    = cloud_storage_config.value.max_duration
      max_bytes       = cloud_storage_config.value.max_bytes

      dynamic "avro_config" {
        for_each = cloud_storage_config.value.avro_config != null ? [cloud_storage_config.value.avro_config] : []
        content {
          write_metadata = avro_config.value.write_metadata
        }
      }
    }
  }

  labels = merge(var.tags, each.value.labels)
}

# Pub/Sub Schemas
resource "google_pubsub_schema" "schemas" {
  for_each = var.schemas

  name       = "${var.name_prefix}-${each.key}"
  type       = each.value.type
  definition = each.value.definition
}

# Pub/Sub Lite Topics
resource "google_pubsub_lite_topic" "lite_topics" {
  for_each = var.lite_topics

  name   = "${var.name_prefix}-${each.key}"
  zone   = each.value.zone
  region = each.value.region

  partition_config {
    count    = each.value.partition_config.count
    capacity = each.value.partition_config.capacity
  }

  retention_config {
    per_partition_bytes = each.value.retention_config.per_partition_bytes
    period             = each.value.retention_config.period
  }

  reservation_config {
    throughput_reservation = each.value.reservation_config.throughput_reservation
  }
}

# Pub/Sub Lite Subscriptions
resource "google_pubsub_lite_subscription" "lite_subscriptions" {
  for_each = var.lite_subscriptions

  name   = "${var.name_prefix}-${each.key}"
  topic  = google_pubsub_lite_topic.lite_topics[each.value.topic_key].name
  zone   = each.value.zone
  region = each.value.region

  delivery_config {
    delivery_requirement = each.value.delivery_config.delivery_requirement
  }
}

# IAM bindings for topics
resource "google_pubsub_topic_iam_binding" "topic_bindings" {
  for_each = var.topic_iam_bindings

  topic   = google_pubsub_topic.topics[each.value.topic_key].name
  role    = each.value.role
  members = each.value.members

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# IAM bindings for subscriptions
resource "google_pubsub_subscription_iam_binding" "subscription_bindings" {
  for_each = var.subscription_iam_bindings

  subscription = google_pubsub_subscription.subscriptions[each.value.subscription_key].name
  role         = each.value.role
  members      = each.value.members

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}