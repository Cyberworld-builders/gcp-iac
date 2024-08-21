terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# create a randome string for a suffix
resource "random_id" "bucket_name_suffix" {
  byte_length = 8
}

provider "google" {
  credentials = file("system-root-key.json")
  project     = "tnclient-system-root"
  region      = "us-central1"
}

locals {
    org_id = var.org_id
    billing_account_id = var.billing_account_id
    system_root_folder_id = var.system_root_folder_id
    system_root_project_id = var.system_root_project_id
    system_suffix = substr(random_id.bucket_name_suffix.hex, 0, 8)
}

# Create a Folder for Terraform Managed Resources as a chile od the root folder
resource "google_folder" "tf_managed_resources" {
  display_name = "Terraform Managed Resources"
    parent       = "folders/${local.system_root_folder_id}" 
}

# Create a Project for Terraform Managed Resources
resource "google_project" "tf_managed_resources" {
  name       = "tf-managed-resources"
  project_id = "tf-managed-resources-${local.system_suffix}"
  folder_id  = local.system_root_folder_id
  billing_account = local.billing_account_id
}

# Create a Service Account for Terraform Managed Resources
resource "google_service_account" "tf_managed_resources" {
  account_id   = "tf-managed-resources"
  display_name = "Terraform Managed Resources"
  project      = google_project.tf_managed_resources.project_id
}

output "suffix" {
  value = local.system_suffix  
}