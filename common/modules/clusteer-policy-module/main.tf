locals {
  tags_json = {
    for tag in var.tags :
    tag.key => {
      type  = "fixed"
      value = tag.value
    }
  }

  # Inject ``aws_attributes.instance_profile_arn`` ONLY when the caller
  # supplies a non-empty ARN. An empty input emits NO IP attribute in
  # the policy body, so end-users attach any IP made available via the
  # workspace-level ``databricks_group_role`` bindings (or none).
  #
  # An unconditional inject would emit ``"value": ""`` for policies
  # that do not source an ARN, and Databricks rejects every cluster
  # launch under such a policy with "instance profile ARN is ill
  # formed". The v1 baseline at
  # ``EnterpriseDatabricks-dbx-operational-terraform/common/cluster-policies/credentialpassthroughjob.json``
  # pinned an IP only on the credential-passthrough job policy; this
  # module preserves that contract by gating the inject on a non-empty
  # caller ARN. The base module sources the IP for ``cp_jobs`` from
  # ``var.instance-profile-configs`` filtered to ``is_meta_role: true``
  # via ``local.meta_instance_profile_arn``.
  instance_profile_attr = var.instance_profile_arn != "" ? {
    "aws_attributes.instance_profile_arn" = {
      type  = "fixed"
      value = var.instance_profile_arn
    }
  } : {}

  common_policy_attrs = {
    "runtime_engine" = {
      type         = "unlimited"
      defaultValue = "STANDARD"
      isOptional   = true
    }
    "custom_tags.ASV" = {
      type  = "fixed"
      value = "ASVOPERATIONALDATAANALYTICSPLATFORM"
    }
    "custom_tags.CMDBEnvironment" = {
      type  = "fixed"
      value = "ENVPROPERATIONALDATAANALYTICSPLATFORM"
    }
    "custom_tags.OwnerContact" = {
      type  = "fixed"
      value = "databricks2@capitalone.com"
    }
    "custom_tags.Component" = {
      type  = "fixed"
      value = "BAPOPERATIONALDBRKS"
    }
    "custom_tags.BA" = {
      type  = "fixed"
      value = "BAOPERATIONALDATAANALYTICSPLATFORM"
    }
    "aws_attributes.availability" = {
      type  = "fixed"
      value = "ON_DEMAND"
    }
    "spark_conf.spark.hadoop.environment" = {
      type  = "fixed"
      value = upper(var.environment)
    }
    "spark_env_vars.cots_newrelic_key" = {
      type   = "fixed"
      value  = "{{secrets/env_params/cots_newrelic_key}}"
      hidden = true
    }
    "cluster_log_conf.type" = {
      type  = "fixed"
      value = "DBFS"
    }
  }

  dbus_per_hour_attr = var.include_dbus_per_hour ? {
    "dbus_per_hour" = {
      type     = "range"
      maxValue = var.dbus_per_hour
    }
  } : {}

  filtered_policy_overrides = {
    for key, value in var.policy_overrides : key => value
    if !(try(value.value, "__NO_VALUE__") == null || try(value.value, "__NO_VALUE__") == "")
  }
}

resource "databricks_cluster_policy" "cluster_policy" {
  # Explicit '/' separator: callers (e.g.
  # workspace-interactive-subgraph.tf) pass ``base_path = "${path.module}/../.."``
  # without a trailing slash, which would otherwise compose
  # ``./../..cluster-policies/...`` and trip terraform's ``file()``.
  # An adjacent ``//`` is a valid POSIX path so this also works when
  # a future caller passes a base_path that DOES end in ``/``.
  definition = jsonencode(merge(
    jsondecode(file("${var.base_path}/${var.cluster_policy_path}")),
    local.common_policy_attrs,
    local.dbus_per_hour_attr,
    local.instance_profile_attr,
    local.tags_json,
    local.filtered_policy_overrides
  ))
  name = lower("${var.cluster_policy_name}")
}



resource "databricks_permissions" "can_use_cluster_policy" {
  depends_on        = [databricks_cluster_policy.cluster_policy]
  cluster_policy_id = databricks_cluster_policy.cluster_policy.id

  dynamic "access_control" {
    for_each = var.cluster_policy_permissions
    content {
      group_name       = access_control.value.group_name
      permission_level = access_control.value.permission_level
    }
  }
}