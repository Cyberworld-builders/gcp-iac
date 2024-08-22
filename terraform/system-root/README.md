# System Root Setup
You will need to use a Service Account with privileges above the Terraform-managed resources boundary in order to apply these configs. I will provide the commands and some instructions to set this up. You may also perform each of the pre-requisite steps from the console as well if you prefer.

> **Why is this necessary?**:  Managing access effectively and efficiently can be a challenge when you follow the *Principle of Least Privilege*. Without an effective access management strategy and toolkit, Organization owners will often provide excessive permissions in order to quickly unblock developers. By creating this Terraform config, Engineers can commit code that expresses the precise privileges that Owners need to grant to the Terraform Agent. So rather than fumbling through the console clicking on things until they work, Owners and Admins can run a simple apply command to update permissions to the latest config. This also eliminates the need to share credentials and keeps the Terraform-managed resources securely bound to their own sandbox, keeping sensitive projects like backups, billing and secops protected from less-privileged developers.

## Requirements
1.  The **`gcloud` CLI**
2.  **Terraform** installed in your environment.
3.  A *highly-privileged* **GCP User or Service Account**.

## Reference Material
If you do not already meet the requirements for item 1 or 2, follow the links below for instructions.
- [Google - Installing the gcloud CLI](https://cloud.google.com/sdk/docs/install)
- [Hashicorp - Installing Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

## I. Bootstrapping the System Root Setup
This stage walks you through setting up the *highly-privileged* Service Account for creating and managing the Terraform-managed resources structure.

### 1. Authenticate with the `gcloud` CLI.
```sh
gcloud auth login
```

### 2. Create a System Root Folder 
Create a System Root Folder  with the Organization as the parent to contain the TF Agent Project, the TF Agent Service Account, and the TF-managed resources Folder. 

**Find the Organziation ID**
```sh
gcloud organizations list
```

**Create the System Root Folder**
```sh
gcloud resource-manager folders create \
    --display-name="MyName System Root" \
    --organization="ORGANIZATION_ID"
```

### 3. Create a System Root Project
Service Accounts are associated with a Project. Create a System Root Project with the Organization as the parent to use for the System Root Service Account.

```sh
gcloud projects create PROJECT_ID \
    --name="PROJECT_NAME" \
    --organization=ORGANIZATION_ID \
    --set-as-default
```

### 4. Create a System Root Service Account
 Create a System Root Service Account to set up and manage all of the resources that will be bound within the TF-managed resources Folder structure.

 ```sh
gcloud iam service-accounts create SERVICE_ACCOUNT_NAME \
    --display-name="DISPLAY_NAME" \
    --project=PROJECT_ID
```

### 5. Generate an IAM key JSON
Generate an IAM key JSON for the System Root Service Account. This will be used to allow Terraform to authenticate as a highly privileged Service Account.

```sh
gcloud iam service-accounts keys create system-root-key.json \
    --iam-account=SERVICE_ACCOUNT_EMAIL \
    --project=PROJECT_ID
```

> NOTE: *DELETE THIS KEY WHEN YOU ARE DONE AND GENERATE A NEW ONE EACH TIME YOU PERFORM THIS TYPE OF ADMINISTRATIVE WORKFLOW.* This is a sensitive key for a highly-privileged Service Account. It is not good practice to use these types of keys frequently. For a frequent-use, long-term solution we will be setting up short-lived tokens via Workload Identity Provider for a Terraform Agent with more limited permissions. Storing long-lived keys is a serious security risk.


### 6. Enable Cloud Billing API for the System Root Project
```sh
gcloud services enable cloudbilling.googleapis.com --project=PROJECT_ID
```

### 7. Grant Folder Admin to your System Root Service Account 
*(Untested. I did this manually in the console.)*

```sh
gcloud organizations add-iam-policy-binding ORGANIZATION_ID \
    --member="serviceAccount:SERVICE_ACCOUNT_EMAIL" \
    --role="roles/resourcemanager.folderAdmin"
```

### 8. Grant `roles/billing.user` to your System Root Service Account
```sh
gcloud beta billing accounts add-iam-policy-binding BILLING_ACCOUNT_ID \
    --member="serviceAccount:SERVICE_ACCOUNT_EMAIL" \
    --role="roles/billing.user"
```

### 9.0 Grant `roles/resourcemanager.projectCreator` to your System Root Service Account
```sh
gcloud organizations add-iam-policy-binding ORGANIZATION_ID \
    --member="serviceAccount:SERVICE_ACCOUNT_EMAIL" \
    --role="roles/resourcemanager.projectCreator"
```

### 9.1 Create a KMS Key for Storage Folder Encryption
We're going to store the Terraform state for our System Root in a Storage Folder in GCP. These objects need to be encrpyted for data protection. 

**Enable the Cloud KMS API for the System Root Project**
```sh
gcloud services enable cloudkms.googleapis.com --project my-project-id
```

**Make sure billing is enabled for the System Root Project**
```sh
gcloud beta billing projects link myname-system-root --billing-account=012345-6789AB-CDEF01
```

**Create a KMS Key Ring:**
   ```bash
   gcloud kms keyrings create my-keyring \
     --location us-central1 \
     --project your-project-id
   ```
   * This command creates a key ring named `my-keyring` in the `us-central1` region of your project.

**Create a KMS Key**
```sh
gcloud kms keys create my-key \
  --keyring my-keyring \
  --location us-central1 \
  --project your-project-id \
  --purpose encryption
```
   * This command creates a key named `my-key` within the `my-keyring` key ring. The key is intended for encryption 
   
### 9.2 Create a Storage Bucket for System Root Terraform State
**Create Bucket**
```sh
gcloud storage buckets create your-bucket-name \
    --location us-central1 \
    --project your-project-id \
    --folder folders/your-folder-id
```

### 9.2 Grant KMS Permissions to the System Root Service Account
The System Root Service Account needs to be 

## II. Creating the Terraform-managed Resources Structure

### 10. Configure your `terraform.tfvars` file
**Copy the example file**
```sh
cp terraform.tfvars.example terraform.tfvars
```

**Update the Organization Id**
```sh
gcloud organizations list --filter="displayName:myorganization.com" --format="value(ID)" | xargs -I {} sed -i 's/^org_id = ".*"/org_id = "{}"/' terraform.tfvars
```

**Show the Organization Id**
If anything goes wrong with that command, you can simply list your organizations, copy the id and the paste it in the `terraform.tfvars` file.
```sh
gcloud organizations list
```

**You can do the same with the billing_account_id**

**The Quick Way**
```sh
gcloud beta billing accounts list --filter="displayName:MyBillingAccountName" --format="value(ACCOUNT_ID)" | xargs -I {} sed -i 's/^billin
g_account_id = ".*"/billing_account_id = "{}"/' terraform.tfvars
```

**If you're not sure what your exact billing account name is**
```sh
gcloud beta billing accounts list
```

**If you need to list your System Root Folder Id**
```sh
gcloud resource-manager folders list --organization=ORGANIZATION_ID
```

Then copy and paste the id. Make sure you update the System Root Project Id as well. Use the example file to check your format. It should look something like this:
```
org_id = "1234567890"
billing_account_id = "123QWE-123QWE-123QWE"
system_root_folder_id = "123454321"
system_root_project_id = "myname-system-root"
```

### 11. Update the System Root Terraform State Bucket and Project Names
These values cannot be passed into Terraform as variables. They currently represent values that were set on a development account. Update them before you proceed.
```hcl
# main.tf

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  backend "gcs" {
    # This bucket name will need to be updated
    bucket  = "tnclient-system-root-tfstate-394b68bc" <----THIS...
    prefix  = "terraform/state"    
  }
}

# create a randome string for a suffix
resource "random_id" "bucket_name_suffix" {
  byte_length = 8
}

provider "google" {
  credentials = file("system-root-key.json")
  project     = "tnclient-system-root" <----- ...AND THIS
  region      = "us-central1"
}
```

### 12. Apply Your Terraform Config

**Initialize your config**
```sh
terraform init
```

**Run the plan command to review**
```sh
terraform plan
```

**Review the plan and apply the changes**
```sh
terraform apply
```

This should create the following resources:
- A Folder to sandbox Terraform-managed resources.
- A Project to manage access for the Terraform Agent.
- A Service Account to manage all resources bound to the Terraform-managed resources Folder.

## III. Storing Credentials in the Repository


### 12. Generate 