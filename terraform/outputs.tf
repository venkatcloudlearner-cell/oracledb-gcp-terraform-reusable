# OPTIONAL: add non-secret outputs as needed; keep resource references consistent.
# Never output the ADMIN password or wallet contents. IDs do not prove SQL connectivity.
output "vpc_id" {
  value = local.vpc_id
}
output "client_subnet_id" {
  value = local.application_subnet_id
}
output "odb_network_id" {
  value = local.odb_network_id
}
output "odb_subnet_id" {
  value = local.odb_subnet_id
}
output "database_id" {
  value = try(google_oracle_database_autonomous_database.demo[0].id, null)
}
