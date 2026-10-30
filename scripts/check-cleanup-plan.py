"""Reject partial cleanup plans that modify resources outside the chosen scope."""
import json
import sys

allowed = {
    "database-only": {"google_oracle_database_autonomous_database"},
    "client-only": {"google_compute_instance", "google_compute_firewall", "google_compute_router", "google_compute_router_nat"},
    "odb-network-and-database": {"google_oracle_database_autonomous_database", "google_oracle_database_odb_subnet", "google_oracle_database_odb_network"},
}
scope, path = sys.argv[1:]
plan = json.load(open(path, encoding="utf-8"))
for resource in plan.get("resource_changes", []):
    actions = resource["change"]["actions"]
    if actions in (["no-op"], ["read"]):
        continue
    if actions != ["delete"] or resource["type"] not in allowed[scope]:
        raise SystemExit(f"Cleanup refused: unexpected {actions} for {resource['address']}")
print("Partial cleanup verified: only selected resource types will be deleted.")
