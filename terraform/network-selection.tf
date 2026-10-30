# Existing networks remain owned by their original configuration/state.
variable "network_mode" {
  type    = string
  default = "create"
  validation {
    condition     = contains(["create", "existing"], var.network_mode)
    error_message = "Choose create or existing."
  }
}
variable "existing_vpc_id" {
  type    = string
  default = ""
  validation {
    condition     = var.network_mode != "existing" || startswith(var.existing_vpc_id, "projects/${var.project_id}/")
    error_message = "Existing mode requires a full projects/PROJECT_ID/... resource ID in this project."
  }
}
variable "existing_application_subnet_id" {
  type    = string
  default = ""
  validation {
    condition     = var.network_mode != "existing" || startswith(var.existing_application_subnet_id, "projects/${var.project_id}/")
    error_message = "Existing mode requires a full projects/PROJECT_ID/... resource ID in this project."
  }
}
variable "existing_odb_network_id" {
  type    = string
  default = ""
  validation {
    condition     = var.network_mode != "existing" || startswith(var.existing_odb_network_id, "projects/${var.project_id}/")
    error_message = "Existing mode requires a full projects/PROJECT_ID/... resource ID in this project."
  }
}
variable "existing_odb_subnet_id" {
  type    = string
  default = ""
  validation {
    condition     = var.network_mode != "existing" || startswith(var.existing_odb_subnet_id, "projects/${var.project_id}/")
    error_message = "Existing mode requires a full projects/PROJECT_ID/... resource ID in this project."
  }
}
locals {
  vpc_id                = var.network_mode == "create" ? google_compute_network.demo[0].id : var.existing_vpc_id
  application_subnet_id = var.network_mode == "create" ? google_compute_subnetwork.client[0].id : var.existing_application_subnet_id
  odb_network_id        = var.network_mode == "create" ? try(google_oracle_database_odb_network.demo[0].id, null) : var.existing_odb_network_id
  odb_subnet_id         = var.network_mode == "create" ? try(google_oracle_database_odb_subnet.database[0].id, null) : var.existing_odb_subnet_id
}

# Keep these flags at their post-cleanup values to avoid recreating removed resources.
variable "retain_database" {
  type    = bool
  default = true
}
variable "retain_odb_network" {
  type    = bool
  default = true
  validation {
    condition     = var.retain_odb_network || !var.retain_database
    error_message = "Remove the database together with its ODB network."
  }
}
variable "retain_client" {
  type    = bool
  default = true
}
