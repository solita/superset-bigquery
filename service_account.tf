# Create a service account
resource "google_service_account" "superset_sa" {
    account_id   = "superset-sa"
    display_name = "Superset Bigquery access"
    description  = "Allows Superset to access Bigquery"
}

# Grant necessary roles to the service account
resource "google_project_iam_member" "bigquery_roles" {
    for_each = toset([
        "roles/bigquery.dataViewer",
        "roles/bigquery.metadataViewer",
        "roles/bigquery.jobUser"
    ])
    
    project = var.project_id
    role    = each.value
    member  = "serviceAccount:${google_service_account.superset_sa.email}"
}

# Create and download the service account key from GCP console with your browser!