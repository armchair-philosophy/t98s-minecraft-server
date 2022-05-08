terraform {
  backend "gcs" {
    bucket = "t98s-mc-testbed-terraform"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.20.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.20.0"
    }
  }
}

locals {
  project = "t98s-mc-testbed"
  region  = "asia-northeast1"
  zone    = "asia-northeast1-a"
}

provider "google" {
  project = local.project
  region  = local.region
}

provider "google-beta" {
  project = local.project
  region  = local.region
}
