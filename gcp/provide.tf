terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "google" {
  credentials = file(var.gcp_credentials_file)
  project = var.gcp_project
  region = var.gcp_region
  zone = var.gcp_zone
}
