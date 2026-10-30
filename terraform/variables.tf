# REQUIRED: set your Google Cloud project ID in terraform.tfvars, not the display name.
variable "project_id" {
  type        = string
  description = "Google Cloud project ID, not its display name."
}
# REQUIRED: set a Google Cloud region verified for your Oracle service in terraform.tfvars.
variable "region" {
  type        = string
  description = "Google Cloud region verified to support your Oracle service and linked tenancy."
}
# CUSTOMIZE in terraform.tfvars: prefix for VPC, subnet, ODB network and database instance names. Changing names after deployment may replace resources.
variable "name_prefix" {
  type    = string
  default = "adbs-demo"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,29}[a-z0-9]$", var.name_prefix))
    error_message = "Use 2-31 lowercase letters, digits and hyphens; begin with a letter and end with a letter or digit."
  }
}
# CUSTOMIZE in terraform.tfvars: application subnet CIDR; verify no overlap with connected networks.
variable "client_cidr" {
  type    = string
  default = "10.20.0.0/24"
  validation {
    condition     = can(cidrnetmask(var.client_cidr))
    error_message = "Supply a valid IPv4 CIDR."
  }
}
# CUSTOMIZE in terraform.tfvars: ODB client subnet CIDR; keep it non-overlapping with the application subnet and connected networks.
variable "database_cidr" {
  type    = string
  default = "10.21.0.0/24"
  validation {
    condition     = can(cidrnetmask(var.database_cidr))
    error_message = "Supply a valid IPv4 CIDR."
  }
}
# KEEP true normally. Disable only for an intentional deletion, after reviewing the plan.
variable "deletion_protection" {
  type    = bool
  default = true
}
# STAGE CONTROL: false for network-only setup; true to include ADB-S. Switching back to false after creation proposes database deletion.
variable "create_database" {
  type    = bool
  default = false
}
# REQUIRED before database creation: supported API version value for your chosen region, supplied in terraform.tfvars.
variable "database_version" {
  type        = string
  default     = ""
  description = "API version value confirmed available in the chosen region; do not guess the version label."
}
# CUSTOMIZE before database creation: notification email in terraform.tfvars. Do not publish personal values in examples.
variable "contact_email" {
  type    = string
  default = ""
}
# REQUIRED before database creation: supply TF_VAR_admin_password securely. Never hard-code a real password here. Sensitive values can still be stored in state/plans.
variable "admin_password" {
  type      = string
  sensitive = true
  default   = ""
}
# CUSTOMIZE in terraform.tfvars: database ECPUs. Review service limits and cost; this does not size a client VM.
variable "compute_count" {
  type    = number
  default = 2
}
# CUSTOMIZE in terraform.tfvars: database storage in TB. Review service limits and cost.
variable "storage_tb" {
  type    = number
  default = 1
}

# CUSTOMIZE in terraform.tfvars: GCP Oracle Zone from your ODB network console.
# This is not the Compute Engine zone; changing it replaces the ODB network.
# null lets the service choose a zone when this optional input is omitted.
variable "gcp_oracle_zone" {
  type        = string
  default     = null
  description = "GCP Oracle Zone for the ODB network, for example us-east4-b-r1."
}

# CUSTOMIZE before creating a separate deployment. Existing defaults preserve Part 1.
variable "database_resource_id" {
  type        = string
  default     = null
  description = "Google Cloud database resource ID; null preserves the Part 1 name."
}
variable "database_name" {
  type        = string
  default     = "ADBS26AI"
  description = "Oracle database name, distinct for each database."
}
variable "database_display_name" {
  type    = string
  default = "ADBS-26ai"
}
variable "private_endpoint_label" {
  type    = string
  default = "adbs26ai"
}

# false for a second deployment in a project whose APIs are already enabled.
# One state should own the project-wide API enablement resources.
variable "manage_project_apis" {
  type    = bool
  default = true
}
