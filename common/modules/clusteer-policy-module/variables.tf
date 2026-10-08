variable "cluster_policy_name" {
  type    = string
  default = "null"
}

variable "cluster_policy_permissions" {
  type = list(object({
    group_name       = string
    permission_level = string
  }))
}

variable "base_path" {
  type    = string
  default = ""
}

variable "dbus_per_hour" {
  type    = number
  default = 0
}

variable "include_dbus_per_hour" {
  type    = bool
  default = true
}

variable "policy_overrides" {
  type    = map(any)
  default = {}
}

variable "cluster_policy_path" {
  type = string
}

variable "environment" {
  type = string
}

variable "instance_profile_arn" {
  type    = string
  default = ""
}

variable "tags" {
  type = list(object({
    key   = string
    value = string
  }))
}