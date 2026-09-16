variable "project_name" {
  type     = string
  nullable = false
}

variable "region_id" {
  type     = string
  nullable = false
}

variable "app_role_name" {
  type     = string
  nullable = false
}

variable "auth_role_name" {
  type     = string
  nullable = false
}

variable "canonical_database_name" {
  type     = string
  nullable = false
}

variable "auth_database_name" {
  type     = string
  nullable = false
}
