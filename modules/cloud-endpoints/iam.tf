# Endpoints Service IAM bindings
resource "google_endpoints_service_iam_binding" "service_bindings" {
  for_each = var.service_iam_bindings

  service_name = google_endpoints_service.endpoints_services[each.value.service_key].service_name
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

# Endpoints Service IAM members
resource "google_endpoints_service_iam_member" "service_members" {
  for_each = var.service_iam_members

  service_name = google_endpoints_service.endpoints_services[each.value.service_key].service_name
  role         = each.value.role
  member       = each.value.member

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}
