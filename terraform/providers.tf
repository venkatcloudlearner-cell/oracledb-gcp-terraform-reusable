# Set project_id and region in terraform.tfvars; keep these variable references.
# Authentication uses your local ADC sign-in; do not put credentials in this file.
provider "google" {
  project = var.project_id
  region  = var.region
}
