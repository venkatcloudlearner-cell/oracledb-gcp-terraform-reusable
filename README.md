# Oracle Database@Google Cloud: reusable Terraform

Provision an independent ADB-S example using configurable Terraform inputs and reviewed GitHub Actions operations. Select 19c or 26ai through the database_version workflow input.

## Configuration

- Resource definitions: `terraform/*.tf`
- Example inputs: `terraform/environments/19c.tfvars`
- Validation workflow: `.github/workflows/terraform-checks.yml`
- Reviewed operations: `.github/workflows/terraform-19c.yml`
- Dedicated state prefix: `adbs/19c-example`

Configure repository variables `GCP_PROJECT_ID`, `TF_STATE_BUCKET`, `TF_SERVICE_ACCOUNT`, and `WIF_PROVIDER`. Configure `terraform-plan` and `terraform-apply` environments, with required review on apply and main-branch restrictions. Save `ADB19C_ADMIN_PASSWORD` as a secret in `terraform-plan`. Workload Identity Federation must explicitly trust this repository and its environments.

The project APIs must already be enabled; this example uses `manage_project_apis = false`. Do not reuse an existing deployment's state prefix. Review CIDRs for overlap before deployment.

## Operations

Run **Terraform 19c create and destroy** manually on main:

1. `deploy`: review and approve creation.
2. Verify the database and connection.
3. `prepare-destroy`: enter `adbs-19c`, review and approve disabling deletion protection.
4. `destroy`: enter `adbs-19c`, review and approve deleting only this example's resources.

Each run plans before approval and applies the saved plan after checksum verification. Binary plans stay in private GCS storage. Retained plan/state versions need an appropriate retention policy.

The workflow cannot prompt interactively for passwords. Never enter a password in dispatch text fields. State and plans may contain sensitive values.

## Validation status

Terraform formatting and schema validation passed locally. This repository's cloud deployment has not yet been run. Creating resources incurs charges; destruction removes database data and example infrastructure. Shared bucket and authentication infrastructure are not destroyed by this configuration.

## Database version input

The manual workflow accepts `database_version` as a choice: `19c` or `26ai`.
It passes the selection as a Terraform CLI variable, which takes precedence over the sample input file.
Keep the selected version unchanged for subsequent updates and cleanup of the same deployment.
The sample names and state prefix still identify one example deployment; selecting a different version does not create a second independent deployment. Use separate names and state for another environment.


### Choose new or existing networks

In **Run workflow**, choose **Network mode** before starting the plan:

| Choice | What Terraform manages |
| :--- | :--- |
| `create` | A new VPC, application subnet, ODB network and Client ODB subnet, plus the database and client VM infrastructure. |
| `existing` | A new database and client VM with its IAP SSH firewall rule, using the network IDs you provide. Existing networks, subnets, router and NAT remain outside this deployment's state. |

For `create`, leave the four existing-network fields blank. For `existing`, provide full resource IDs:

```text
existing_vpc_id: projects/YOUR_PROJECT_ID/global/networks/YOUR_VPC
existing_application_subnet_id: projects/YOUR_PROJECT_ID/regions/us-east4/subnetworks/YOUR_APP_SUBNET
existing_odb_network_id: projects/YOUR_PROJECT_ID/locations/us-east4/odbNetworks/YOUR_ODB_NETWORK
existing_odb_subnet_id: projects/YOUR_PROJECT_ID/locations/us-east4/odbNetworks/YOUR_ODB_NETWORK/odbSubnets/YOUR_CLIENT_ODB_SUBNET
```

Select resources in the same project and deployment region. The application subnet must belong to the supplied VPC, and the ODB network must be associated with that VPC. The ODB subnet must be a Client subnet in that ODB network. Confirm available address capacity, private connectivity and DNS before applying. If the new VM needs internet access for packages, the existing application subnet needs suitable outbound access; existing mode does not create a router or Cloud NAT.

The workflow passes these values to `network-selection.tf`. Conditional resource counts create networks only in `create` mode; local values select either their generated IDs or your existing IDs. The existing resources are referenced, not imported into this state. Destroying this example removes its database, VM and firewall rule while retaining the supplied networks.

Keep the selected network mode and IDs unchanged for later runs and cleanup. Changing modes after deployment can propose deletion of managed networks or database replacement. Review the plan; use a separate state prefix and unique resource names for another independent deployment. The current workflow still targets one example at `adbs/19c-example`.

For this walkthrough, select `create` and database version `19c`. Leave **confirmation** blank for `deploy`; it is required only for `prepare-destroy` and `destroy`. Deployment does not schedule automatic cleanup.


## Cleanup scopes

Choose **cleanup_scope** before running cleanup:

| Choice | Resources removed | Resources retained |
| :--- | :--- | :--- |
| `database-only` | This deployment's ADB-S database | ODB network, ODB subnet, VPC, application subnet and client resources |
| `client-only` | Client VM, dedicated IAP SSH firewall, and dedicated router/NAT if created | Database and networks |
| `odb-network-and-database` | This deployment's database, ODB client subnet and ODB network | VPC, application subnet and client resources |
| `all` | All resources managed in this example's state | Referenced existing networks and separately managed project APIs |

For partial cleanup, Terraform changes resource counts through `retain_database`, `retain_odb_network` and `retain_client`. It uses a normal plan rather than routine resource targeting. The workflow checks the saved partial cleanup plan and refuses any creation, update, replacement, or deletion outside the selected resource types. The complete plan still requires your approval.

1. Select the same database version, network mode and existing resource IDs used during deployment.
2. Choose the cleanup scope and operation `prepare-destroy`. Enter `adbs-19c` as confirmation. Review and approve the plan that disables deletion protection. This preparation currently disables protection on all protected resources managed by this example, including resources you may retain.
3. Wait for preparation to finish. Run again with operation `destroy`, the same cleanup scope and confirmation. Review each deletion before approving.
4. For `odb-network-and-database`, the database is removed before its subnet and network. This option is rejected in `existing` network mode: the workflow does not own those networks. Other resources attached outside this state can also prevent network deletion; remove or relocate those dependencies separately.
5. After partial cleanup, keep the corresponding flags false in your deployment input file before any future `deploy`: `retain_database = false` for database-only; `retain_client = false` for client-only; both `retain_database = false` and `retain_odb_network = false` for ODB cleanup. Otherwise a later deploy will recreate the removed resources. Commit that intended configuration before continuing. Repeated cleanup choices are not cumulative automatically; the plan guard rejects unexpected recreations.
6. Re-enable `deletion_protection = true` for retained resources in the input file and run a reviewed deployment after preserving the cleanup flags. Do not change the state prefix to delete the same deployment.

Deleting a database removes its data. Confirm backup and retention requirements before approval. For a simple create-and-remove demonstration, use `all`; the other choices support deliberately retaining part of the environment.

The implementation follows Terraform's [configuration-driven resource deletion](https://developer.hashicorp.com/terraform/language/resources/destroy) and avoids routine [resource targeting](https://developer.hashicorp.com/terraform/tutorials/state/resource-targeting).
