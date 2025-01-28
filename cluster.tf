terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.19.0"
    }
  }
}

# Deploy the Kubernetes cluster
resource "google_container_cluster" "autopilot" {
    name = "superset-cluster"

    enable_autopilot = true
    deletion_protection = false
}

data "google_client_config" "current" {}

# Configure Helm and Kubectl for Superset deployment
provider "helm" {
    kubernetes {
        host = "https://${google_container_cluster.autopilot.endpoint}"
        cluster_ca_certificate = base64decode(google_container_cluster.autopilot.master_auth.0.cluster_ca_certificate)
        token = data.google_client_config.current.access_token
    }
}

provider "kubectl" {
    host = "https://${google_container_cluster.autopilot.endpoint}"
    cluster_ca_certificate = base64decode(google_container_cluster.autopilot.master_auth.0.cluster_ca_certificate)
    token = data.google_client_config.current.access_token
    load_config_file = false
}

# Create random (internal) passwords automatically for security
resource "random_password" "postgres" {
    length = 30
}
resource "random_password" "superset_secret" {
    length = 30
}

# Deploy Superset with Helm
resource "helm_release" "superset" {
    name = "superset"
    repository = "https://apache.github.io/superset"
    chart = "superset"
    namespace = "superset"
    create_namespace = true
    values = [jsonencode({
        postgresql = {
            postgresqlPassword = random_password.postgres.result
        }
        configOverrides = {
            secret = "SECRET_KEY = '${random_password.superset_secret.result}'"
        }
        # psycopg2 non-binary won't work, container doesn't have a C compiler
        bootstrapScript = <<EOF
        #!/bin/bash
        pip install psycopg2-binary==2.9.10 sqlalchemy-bigquery==1.12.1
        EOF
    })]
}

# If desired, expose Superset via public IP
resource "kubectl_manifest" "superset_ingress" {
    count = var.expose ? 1 : 0
    depends_on = [helm_release.superset]
    yaml_body = "${file("./ingress.yaml")}"
}