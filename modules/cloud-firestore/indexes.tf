# Firestore Indexes
resource "google_firestore_index" "indexes" {
  for_each = var.firestore_indexes

  project    = var.project_id
  database   = var.create_database ? google_firestore_database.database[0].name : var.database_id
  collection = each.value.collection

  dynamic "fields" {
    for_each = each.value.fields
    content {
      field_path   = fields.value.field_path
      order        = fields.value.order
      array_config = fields.value.array_config
    }
  }

  query_scope = each.value.query_scope
  api_scope   = each.value.api_scope
}