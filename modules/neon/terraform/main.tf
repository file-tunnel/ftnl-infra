resource "neon_project" "prod" {
  name      = var.project_name
  region_id = var.region_id
}

resource "neon_role" "app" {
  project_id = neon_project.prod.id
  branch_id  = neon_project.prod.default_branch_id
  name       = var.app_role_name
}

resource "neon_role" "auth" {
  project_id = neon_project.prod.id
  branch_id  = neon_project.prod.default_branch_id
  name       = var.auth_role_name
}

resource "neon_database" "canonical" {
  project_id = neon_project.prod.id
  branch_id  = neon_project.prod.default_branch_id
  name       = var.canonical_database_name
  owner_name = neon_role.app.name
}

resource "neon_database" "auth" {
  project_id = neon_project.prod.id
  branch_id  = neon_project.prod.default_branch_id
  name       = var.auth_database_name
  owner_name = neon_role.auth.name
}
