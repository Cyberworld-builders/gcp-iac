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
