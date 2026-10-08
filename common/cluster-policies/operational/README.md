# Operational cluster policy bodies

The 2 JSON files in this directory are the entire cluster-policy surface of
the operational workspace shape. Each is wrapped by
[`common/modules/cluster-policy-module/main.tf`](../../modules/cluster-policy-module/main.tf),
which merges in:

- 5 SCP-mandatory `custom_tags.*` as `type = "fixed"` (ASV, BA, OwnerContact, Component, CMDBEnvironment)
- `runtime_engine`, `aws_attributes.{availability,zone_id}`
- `cluster_log_conf.{type,path}` (path = `dbfs:/cluster-logs/<policy_name>`)
- `spark.hadoop.environment` from the per-workspace `var.environment`
- `spark_env_vars.cots_newrelic_key` from the env_params secret scope
- `custom_tags.Group` (unlimited, optional)
- `dbus_per_hour` as range with the per-policy `var.dbus_per_hour` maxValue

`aws_attributes.instance_profile_arn` is **conditionally** injected by the
wrapper -- only when the caller passes a non-empty `var.instance_profile_arn`.
In this directory **only `cp_jobs.json` (the credential-passthrough job
policy) gets the IP attribute injected**, sourced from the workspace's meta
IP (`local.meta_instance_profile_arn` in `workspace-base-setup-uc.tf`,
filtered to the `is_meta_role: true` entry of `var.instance-profile-configs`
-- today: `CapOne-SPR-OP-Instance-Profile`). This restores the v1 baseline
at `EnterpriseDatabricks-dbx-operational-terraform/common/cluster-policies/credentialpassthroughjob.json`,
which pinned the same ARN as `type = "fixed"`.

`uc_jobs` does **not** receive the IP attribute -- end-users may attach
any IP that the LOB users-group is bound to via
`module.databricks-group-role` (or none). Pinning the IP attribute as
`value = ""` on every policy breaks cluster launches with "instance
profile ARN is ill formed", which is why the wrapper opts the 3 UC
policies out of injection entirely.

Terraform's `merge()` resolves last-arg-wins, so the wrapper's defaults
override anything the source JSON happens to declare for those keys.

`cp_jobs.json` additionally pins `kind = CLASSIC_PREVIEW` directly in the
JSON body so the policy lands in the legacy classic compute lane on a
UC-attached workspace. The v1 baseline credential-passthrough spark_confs
(`spark.databricks.passthrough.enabled`,
`spark.databricks.pyspark.trustedFilesystems`, the Talos S3A filesystem
overrides, the Glue catalog confs) are only accepted by the classic
validator. Without the pin, modern UC workspaces route the cluster into
a SINGLE_USER lane and reject those confs at submit time. The wrapper
does not own this attribute -- it flows through the
`merge(jsondecode(file(...)), ...)` call unchanged. Locked by
[`tests/unit/test_cluster_policies_and_warehouse_contract.py::test_operational_cp_jobs_pins_kind_classic_preview`](../../../tests/unit/test_cluster_policies_and_warehouse_contract.py).

## Files

| File | cluster_type | autotermination_minutes (fixed) | dbus_per_hour maxValue (via wrapper) | distilled from |
|---|---|---|---|---|
| `uc_jobs.json` | job (allowlist) | 60 | 200 | `UC_policies/job.json` |
| `cp_jobs.json` | job (allowlist) | 60 | 200 | `credentialpassthroughjob.json` |

## Init-script binding contract

Both files bind init scripts by absolute UC Volume path under
`/Volumes/uc_public/default/init_scripts/`. v2 does not write to any
of those paths -- the script bodies are owned by an external pipeline
on the metastore's UC Volume. The sole exception is `install_talos.sh`,
which v2 uploads to a per-deployment folder for `cp_jobs` only (see
"Per-deployment install_talos.sh" below).

Workspace registry (workspace-level global init scripts) holds exactly
one entry: the lambda-emitted `env` script
(`module.databricks-global-init-configuration` against the trimmed
`global-init-scripts-order` module). Everything else is cluster-scope.

Net cluster-scope binding set per policy:

| Policy | Cluster-scope init scripts (in execution-order numeric index) |
|---|---|
| `operational/uc_jobs` | 8x `global/{proxy,artifactory,config_s3a,config_java_security,install_certs,install_otel,config_jdbc,install_node_exporter}.sh` + `env-scripts/env-operational.sh`, `artifactory_uc_osdg.sh`, `config_ntp.sh`, `install_vault.sh`, `osdg_setup.sh` |
| `operational/cp_jobs` | 8x `global/*` (same as above) + per-deployment `<deployment_name>/install_talos.sh` (injected via `policy_overrides`) |

### Per-deployment install_talos.sh (cp_jobs only)

`cp_jobs` requires `install_talos.sh` to add the Talos S3A filesystem
and Onelake/Glue credential-provider JARs the
`spark.databricks.passthrough.glue.credentialsProviderFactoryClassName`
spark_conf depends on at runtime. v2 uploads the script to a
per-deployment UC Volume folder so each workspace owns its own copy:

```
/Volumes/uc_public/default/init_scripts/<databricks_deployment_name>/install_talos.sh
```

The upload is owned by `module.databricks-cluster-init-scripts-upload`
(operational-only) which reads
`common/cluster-init-scripts/<environment>/install_talos.sh` and
writes the per-deployment path. The `init_scripts.8.volumes.destination`
binding is injected at apply time as a `policy_overrides` entry on
`module.operational_cp_jobs_policy`; `cp_jobs.json` itself only
declares the 8 `global/*` bindings (indices 0..7) so the JSON stays
workspace-agnostic.

## Permissions

Each policy gets exactly one explicit `databricks_permissions` row: `CAN_USE`
to `local.workspace_users_group_display_name` (the LOB users group). All
`CAN_MANAGE` is implicit via `databricks_mws_permission_assignment` ADMIN on
the LOB admins group, Platform_User, Platform_Admin, and ServicePrincipalAdmins.

## Known issue

`config_ntp.sh` exits non-zero on cluster boot. End-user cluster launches
under either of these 2 policies fail at init-script execution until the
script is fixed in place. Tracked as a separate work item.