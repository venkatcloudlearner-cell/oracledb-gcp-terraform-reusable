# OPTIONAL: add non-secret outputs as needed; keep resource references consistent.
# Never output the ADMIN password or wallet contents. IDs do not prove SQL connectivity.
output "vpc_id" {
  value = google_compute_network.demo.id
}
output "client_subnet_id" {
  value = google_compute_subnetwork.client.id
}
output "odb_network_id" {
  value = google_oracle_database_odb_network.demo.id
}
output "odb_subnet_id" {
  value = google_oracle_database_odb_subnet.database.id
}
output "database_id" {
  value = try(google_oracle_database_autonomous_database.demo[0].id, null)
}
