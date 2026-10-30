# Tested version pins for this demo. Keep them unless intentionally upgrading.
# When upgrading, check resource schemas, refresh the lock file, and validate again.
terraform {
  required_version = "= 1.16.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "= 8.9.0"
    }
  }
}
