# Firestore Security Rules
resource "google_firebaserules_ruleset" "firestore_rules" {
  for_each = var.security_rulesets

  project = var.project_id
  source {
    files {
      name    = "firestore.rules"
      content = each.value.rules_content
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Firestore Rules Release
resource "google_firebaserules_release" "firestore_release" {
  for_each = var.security_rulesets

  name         = "cloud.firestore/${var.create_database ? google_firestore_database.database[0].name : var.database_id}"
  ruleset_name = google_firebaserules_ruleset.firestore_rules[each.key].name
  project      = var.project_id

  lifecycle {
    replace_triggered_by = [
      google_firebaserules_ruleset.firestore_rules[each.key]
    ]
  }
}