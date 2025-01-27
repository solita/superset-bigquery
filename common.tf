variable "project_id" {
    description = "The ID of the GCP project"
    type = string
}

variable "region" {
    description = "The region to deploy resources in"
    type = string
}

variable "expose" {
    description = "Expose the Superset service publicly - INSECURE WITHOUT AUTHENTICATION!"
    type = bool
    default = false
}

provider "google" {
    project = var.project_id
    region = var.region
}
