terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  backend "gcs" {
    # This bucket name will need to be updated
    bucket  = "myname-system-root-tfstate-394b68bc" 
    prefix  = "terraform/state"    
  }
}

provider "google" {
  credentials = file("system-root-key.json")
  project     = "myname-system-root"
  region      = "us-central1"
}