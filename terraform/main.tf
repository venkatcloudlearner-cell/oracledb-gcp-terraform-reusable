# CUSTOMER GUIDE: customize input values in terraform.tfvars first.
# Resource labels (demo/client/database) are Terraform addresses, not cloud names.
# Keep ID references consistent; renaming addresses after deployment needs a state migration.

# Enable only the APIs managed by this demo; leave them enabled during cleanup.
resource "google_project_service" "apis" {
  for_each           = var.manage_project_apis ? toset(["compute.googleapis.com", "oracledatabase.googleapis.com"]) : toset([])
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# A VPC is the Google Cloud network. An ODB network connects Oracle resources to it.
resource "google_compute_network" "demo" {
  project                 = var.project_id
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.apis]
}

resource "google_compute_subnetwork" "client" {
  project                  = var.project_id
  name                     = "${var.name_prefix}-client"
  region                   = var.region
  network                  = google_compute_network.demo.id
  ip_cidr_range            = var.client_cidr
  private_ip_google_access = true
}

resource "google_oracle_database_odb_network" "demo" {
  project        = var.project_id
  location       = var.region
  odb_network_id = "${var.name_prefix}-odb"
  # CUSTOMIZE through terraform.tfvars: match the GCP Oracle Zone selected in the console.
  gcp_oracle_zone     = var.gcp_oracle_zone
  network             = google_compute_network.demo.id
  deletion_protection = var.deletion_protection
  # CUSTOMIZE: resource metadata for your environment.
  labels = { environment = "demo", managed_by = "terraform" }
}

resource "google_oracle_database_odb_subnet" "database" {
  project             = var.project_id
  location            = var.region
  odbnetwork          = google_oracle_database_odb_network.demo.odb_network_id
  odb_subnet_id       = "${var.name_prefix}-db-subnet"
  cidr_range          = var.database_cidr
  purpose             = "CLIENT_SUBNET"
  deletion_protection = var.deletion_protection
}

# Kept off until onboarding, networking, supported version and costs are reviewed.
resource "google_oracle_database_autonomous_database" "demo" {
  count                  = var.create_database ? 1 : 0
  project                = var.project_id
  location               = var.region
  autonomous_database_id = coalesce(var.database_resource_id, "${var.name_prefix}-26ai")
  # CUSTOMIZE before first deployment: Oracle database name; follow the service naming rules.
  database = var.database_name
  # CUSTOMIZE: human-readable database display name.
  display_name        = var.database_display_name
  admin_password      = var.admin_password
  odb_network         = google_oracle_database_odb_network.demo.id
  odb_subnet          = google_oracle_database_odb_subnet.database.id
  deletion_protection = var.deletion_protection
  properties {
    # OPTIONAL: workload and licensing changes must match your requirements and entitlement.
    db_workload          = "OLTP"
    license_type         = "LICENSE_INCLUDED"
    db_version           = var.database_version
    compute_count        = var.compute_count
    data_storage_size_tb = var.storage_tb
    # OPTIONAL: review compute/storage autoscaling and potential additional charges.
    is_auto_scaling_enabled         = false
    is_storage_auto_scaling_enabled = false
    # OPTIONAL: choose supported retention and maintenance settings for your policy.
    backup_retention_period_days = 7
    maintenance_schedule_type    = "REGULAR"
    # KEEP true for this wallet-based connection demo; changing it affects client setup.
    mtls_connection_required = true
    # CUSTOMIZE before deployment: private endpoint label using service naming rules.
    private_endpoint_label = var.private_endpoint_label
    customer_contacts {
      email = var.contact_email
    }
  }
  lifecycle {
    # Use the password on creation; manage later password rotations outside Terraform.
    # This provider replaces the database when admin_password changes.
    ignore_changes = [admin_password]

    precondition {
      condition     = !var.create_database || (length(var.admin_password) >= 12 && length(var.admin_password) <= 30)
      error_message = "Supply a 12-30 character ADMIN password before enabling database creation."
    }
    precondition {
      condition     = !var.create_database || (var.database_version != "" && var.contact_email != "")
      error_message = "Confirm a supported database version and set contact_email before creating the database."
    }
  }
}
