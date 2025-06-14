# 🔥 GKE Service Account Management

# GKE Service Account
resource "google_service_account" "gke_sa" {
  count = var.service_account_config.create_new ? 1 : 0

  account_id   = "${var.name_prefix}-gke-sa"
  display_name = "GKE Service Account for ${var.name_prefix}"
  description  = "Service account for GKE cluster nodes"

  depends_on = [
    var.project_id
  ]
}

# IAM roles for GKE service account
resource "google_project_iam_member" "gke_sa_roles" {
  for_each = var.service_account_config.create_new ? toset(var.service_account_config.additional_roles) : toset([])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_sa[0].email}"

  depends_on = [
    google_service_account.gke_sa
  ]
}

# Workload Identity IAM binding
resource "google_service_account_iam_binding" "workload_identity" {
  count = var.service_account_config.enable_workload_identity && var.service_account_config.create_new ? 1 : 0

  service_account_id = google_service_account.gke_sa[0].name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[${var.service_account_config.kubernetes_namespace}/${var.service_account_config.kubernetes_service_account}]"
  ]

  depends_on = [
    google_service_account.gke_sa
  ]
}
