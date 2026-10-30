# Shared state lets Windows and GitHub Actions manage the same resources.
# Bucket settings are supplied separately; never store credentials here.
terraform {
  backend "gcs" {}
}
