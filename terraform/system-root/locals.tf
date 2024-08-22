# create a randome string for a suffix
resource "random_id" "bucket_name_suffix" {
  byte_length = 8
}

locals {
    system_name = "TN Client"
    system_prefix = "tnclient"
    org_id = var.org_id
    billing_account_id = var.billing_account_id
    system_root_folder_id = var.system_root_folder_id
    system_root_project_id = var.system_root_project_id
    system_suffix = substr(random_id.bucket_name_suffix.hex, 0, 8)
    common_labels = {
        "system" = local.system_name
        "prefix" = local.system_prefix
        "org_id" = local.org_id
        "billing_account_id" = local.billing_account_id
        "system_root_folder_id" = local.system_root_folder_id
        "system_root_project_id" = local.system_root_project_id
        "suffix" = local.system_suffix
    }
}