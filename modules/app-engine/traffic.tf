# App Engine Service Split Traffic
resource "google_app_engine_service_split_traffic" "traffic_splits" {
  for_each = var.traffic_splits

  project = var.project_id
  service = each.value.service

  migrate_traffic = each.value.migrate_traffic

  split {
    shard_by    = each.value.split.shard_by
    allocations = each.value.split.allocations
  }

  depends_on = [
    google_app_engine_standard_app_version.standard_versions,
    google_app_engine_flexible_app_version.flexible_versions
  ]
}
