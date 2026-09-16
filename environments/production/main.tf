terraform {
  required_version = ">= 1.12.0, < 2.0.0"

  required_providers {
    neon = {
      source  = "kislerdm/neon"
      version = "= 0.6.3"
    }
  }
}

provider "neon" {}

module "neon" {
  source = "../../modules/neon/terraform"

  project_name            = "file-tunnel-prod"
  region_id               = "aws-us-east-1"
  app_role_name           = "file_tunnel_app"
  auth_role_name          = "file_tunnel_auth"
  canonical_database_name = "canonical"
  auth_database_name      = "auth"
}

# Preserve the five legacy root addresses as state moves into the reusable
# module. No provider operation occurs until an operator runs a reviewed plan.
moved {
  from = neon_project.prod
  to   = module.neon.neon_project.prod
}

moved {
  from = neon_role.app
  to   = module.neon.neon_role.app
}

moved {
  from = neon_role.auth
  to   = module.neon.neon_role.auth
}

moved {
  from = neon_database.canonical
  to   = module.neon.neon_database.canonical
}

moved {
  from = neon_database.auth
  to   = module.neon.neon_database.auth
}
