resource "google_iam_workload_identity_pool" "cicd" {
  provider                  = google-beta
  workload_identity_pool_id = "cicd"
  display_name              = "CI/CD pool"
  description               = "identity pool for DevOps"
}

resource "google_iam_workload_identity_pool_provider" "github-actions" {
  provider                           = google-beta
  workload_identity_pool_id          = google_iam_workload_identity_pool.cicd.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions"
  description                        = "GitHub Actions identity pool"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
    "attribute.repository" = "assertion.repository"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "github-actions" {
  account_id   = "github-actions"
  display_name = "GitHub Actions user for DevOps"
}

resource "google_service_account_iam_binding" "github-actions" {
  service_account_id = google_service_account.github-actions.name
  role               = "roles/iam.serviceAccountUser"
  # 属性値による絞り込み https://cloud.google.com/iam/docs/workload-identity-federation#impersonation
  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.cicd.name}/attribute.repository/${var.github_repository}"
  ]
}

resource "google_project_iam_member" "github-actions" {
  project = local.project
  member  = "serviceAccount:${google_service_account.github-actions.email}"
  for_each = toset([
    "roles/iam.securityAdmin",
    "roles/iam.roleAdmin",
    "roles/servicemanagement.quotaAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/compute.admin",
    "roles/cloudfunctions.admin",
    "roles/storage.admin",
    "roles/iap.admin",
  ])
  role = each.key
}
