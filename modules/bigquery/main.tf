# BigQuery Dataset
resource "google_bigquery_dataset" "datasets" {
  for_each = var.datasets

  dataset_id                  = "${var.name_prefix}_${each.key}"
  friendly_name              = each.value.friendly_name
  description                = each.value.description
  location                   = each.value.location
  default_table_expiration_ms = each.value.default_table_expiration_ms
  delete_contents_on_destroy  = each.value.delete_contents_on_destroy

  labels = merge(var.tags, each.value.labels)

  dynamic "access" {
    for_each = each.value.access_rules
    content {
      role          = access.value.role
      user_by_email = access.value.user_by_email
      group_by_email = access.value.group_by_email
      domain        = access.value.domain
      special_group = access.value.special_group
      iam_member    = access.value.iam_member
    }
  }
}

# BigQuery Tables
resource "google_bigquery_table" "tables" {
  for_each = var.tables

  dataset_id          = google_bigquery_dataset.datasets[each.value.dataset_key].dataset_id
  table_id           = each.key
  friendly_name      = each.value.friendly_name
  description        = each.value.description
  expiration_time    = each.value.expiration_time
  deletion_protection = each.value.deletion_protection

  dynamic "time_partitioning" {
    for_each = each.value.time_partitioning != null ? [each.value.time_partitioning] : []
    content {
      type                     = time_partitioning.value.type
      field                    = time_partitioning.value.field
      expiration_ms           = time_partitioning.value.expiration_ms
      require_partition_filter = time_partitioning.value.require_partition_filter
    }
  }

  dynamic "clustering" {
    for_each = each.value.clustering_fields != null ? [1] : []
    content {
      fields = each.value.clustering_fields
    }
  }

  schema = each.value.schema

  labels = merge(var.tags, each.value.labels)
}

# BigQuery Views
resource "google_bigquery_table" "views" {
  for_each = var.views

  dataset_id = google_bigquery_dataset.datasets[each.value.dataset_key].dataset_id
  table_id   = each.key

  view {
    query          = each.value.query
    use_legacy_sql = each.value.use_legacy_sql
  }

  labels = merge(var.tags, each.value.labels)
}

# BigQuery Routines (Stored Procedures/Functions)
resource "google_bigquery_routine" "routines" {
  for_each = var.routines

  dataset_id      = google_bigquery_dataset.datasets[each.value.dataset_key].dataset_id
  routine_id      = each.key
  routine_type    = each.value.routine_type
  language        = each.value.language
  definition_body = each.value.definition_body
  description     = each.value.description

  dynamic "arguments" {
    for_each = each.value.arguments
    content {
      name          = arguments.value.name
      argument_kind = arguments.value.argument_kind
      mode          = arguments.value.mode
      data_type     = jsonencode(arguments.value.data_type)
    }
  }

  dynamic "return_type" {
    for_each = each.value.return_type != null ? [each.value.return_type] : []
    content {
      type_kind = return_type.value.type_kind
    }
  }
}

# Data Transfer Config
resource "google_bigquery_data_transfer_config" "transfer_configs" {
  for_each = var.data_transfer_configs

  display_name   = "${var.name_prefix}-${each.key}"
  location       = each.value.location
  data_source_id = each.value.data_source_id
  destination_dataset_id = google_bigquery_dataset.datasets[each.value.dataset_key].dataset_id
  
  schedule                = each.value.schedule
  schedule_options {
    disable_auto_scheduling = each.value.disable_auto_scheduling
    start_time             = each.value.start_time
    end_time               = each.value.end_time
  }

  params = each.value.params

  service_account_name = each.value.service_account_name
  notification_pubsub_topic = each.value.notification_pubsub_topic

  email_preferences {
    enable_failure_email = each.value.enable_failure_email
  }
}