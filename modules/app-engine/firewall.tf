# App Engine Firewall Rules
resource "google_app_engine_firewall_rule" "firewall_rules" {
  for_each = var.firewall_rules

  project     = var.project_id
  priority    = each.value.priority
  action      = each.value.action
  source_range = each.value.source_range
  description = each.value.description

  depends_on = [google_app_engine_application.app]
}