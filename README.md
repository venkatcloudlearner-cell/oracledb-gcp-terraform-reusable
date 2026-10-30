# Oracle Database@Google Cloud: reusable Terraform

Provision an independent ADB-S 19c example using configurable Terraform inputs and reviewed GitHub Actions operations.

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
