moved {
  from = google_compute_instance.sqlclient
  to   = google_compute_instance.sqlclient[0]
}
moved {
  from = google_compute_firewall.client_iap_ssh
  to   = google_compute_firewall.client_iap_ssh[0]
}

moved {
  from = google_compute_router_nat.client
  to   = google_compute_router_nat.client[0]
}

moved {
  from = google_compute_router.client
  to   = google_compute_router.client[0]
}

# SQL client VM: uses the existing application subnet, not the ODB subnet.
# CUSTOMIZE: this Compute Engine zone is distinct from gcp_oracle_zone.
variable "client_vm_zone" {
  type    = string
  default = "us-east4-b"
}
# CUSTOMIZE: e2-small is sufficient for this interactive SQLcl demonstration.
variable "client_vm_machine_type" {
  type    = string
  default = "e2-small"
}

# Preserve the original resource address when adopting the optional API control.
moved {
  from = google_project_service.iap
  to   = google_project_service.iap[0]
}

resource "google_project_service" "iap" {
  count              = var.manage_project_apis ? 1 : 0
  project            = var.project_id
  service            = "iap.googleapis.com"
  disable_on_destroy = false
}

# SSH is allowed only from Google's documented IAP TCP forwarding range.
resource "google_compute_firewall" "client_iap_ssh" {
  count         = var.retain_client ? 1 : 0
  project       = var.project_id
  name          = "${var.name_prefix}-iap-ssh"
  network       = local.vpc_id
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["adbs-sqlclient"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# Outbound internet access for packages; the VM has no external IP.
# Cloud NAT and the VM incur usage charges. NAT applies only to this subnet.
resource "google_compute_router" "client" {
  count   = var.network_mode == "create" && var.retain_client ? 1 : 0
  project = var.project_id
  name    = "${var.name_prefix}-client-router"
  region  = var.region
  network = local.vpc_id
}
resource "google_compute_router_nat" "client" {
  count                              = var.network_mode == "create" && var.retain_client ? 1 : 0
  project                            = var.project_id
  name                               = "${var.name_prefix}-client-nat"
  region                             = var.region
  router                             = google_compute_router.client[0].name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = local.application_subnet_id
    source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE"]
  }
}

resource "google_compute_instance" "sqlclient" {
  count               = var.retain_client ? 1 : 0
  project             = var.project_id
  name                = "${var.name_prefix}-sqlclient"
  zone                = var.client_vm_zone
  machine_type        = var.client_vm_machine_type
  deletion_protection = var.deletion_protection
  tags                = ["adbs-sqlclient"]
  labels              = { environment = "demo", managed_by = "terraform" }
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 20
      type  = "pd-balanced"
    }
  }
  network_interface {
    subnetwork = local.application_subnet_id
    # No access_config: no public IP address.
  }
  # No service account attached: the SQL client needs no Google API privileges.
  metadata = {
    enable-oslogin = "TRUE"
  }
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
  depends_on = [google_project_service.iap, google_compute_router_nat.client]
}

output "client_vm_name" {
  value = try(google_compute_instance.sqlclient[0].name, null)
}
output "client_vm_zone" {
  value = try(google_compute_instance.sqlclient[0].zone, null)
}
output "client_vm_private_ip" {
  value = try(google_compute_instance.sqlclient[0].network_interface[0].network_ip, null)
}
