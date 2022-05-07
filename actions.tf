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
    "attribute.ref"        = "assertion.ref"
    "attribute.event_name" = "assertion.event_name"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "github-actions-apply" {
  account_id   = "github-actions-apply"
  display_name = "GitHub Actions user for DevOps"
}

resource "google_service_account" "github-actions-plan" {
  account_id   = "github-actions-plan"
  display_name = "GitHub Actions user for DevOps"
}

resource "google_service_account_iam_binding" "github-actions-apply" {
  service_account_id = google_service_account.github-actions-apply.name
  role               = "roles/iam.workloadIdentityUser"
  # 属性値による絞り込み https://cloud.google.com/iam/docs/workload-identity-federation#impersonation
  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.cicd.name}/attribute.repository/${var.github_repository}"
  ]
  condition {
    title      = "branch restriction"
    expression = "attribute.event_name == \"push\" and attribute.ref == \"refs/heads/main\""
  }
}

resource "google_service_account_iam_binding" "github-actions-plan" {
  service_account_id = google_service_account.github-actions-plan.name
  role               = "roles/iam.workloadIdentityUser"
  # 属性値による絞り込み https://cloud.google.com/iam/docs/workload-identity-federation#impersonation
  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.cicd.name}/attribute.repository/${var.github_repository}"
  ]
}

resource "google_project_iam_member" "github-actions-apply" {
  project = local.project
  member  = "serviceAccount:${google_service_account.github-actions-apply.email}"
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

resource "google_project_iam_member" "github-actions-plan" {
  project  = local.project
  member   = "serviceAccount:${google_service_account.github-actions-plan.email}"
  for_each = toset([])
  role     = each.key
}
