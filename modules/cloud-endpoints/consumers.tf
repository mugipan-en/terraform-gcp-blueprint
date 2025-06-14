# Endpoints Service Consumers
resource "google_endpoints_service_consumers_iam_binding" "consumer_bindings" {
  for_each = var.consumer_iam_bindings

  service_name     = google_endpoints_service.endpoints_services[each.value.service_key].service_name
  consumer_project = each.value.consumer_project
  role             = each.value.role
  members          = each.value.members

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# Endpoints Service Consumer members
resource "google_endpoints_service_consumers_iam_member" "consumer_members" {
  for_each = var.consumer_iam_members

  service_name     = google_endpoints_service.endpoints_services[each.value.service_key].service_name
  consumer_project = each.value.consumer_project
  role             = each.value.role
  member           = each.value.member

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}
