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

  project_name            = "file-tunnel-preview"
  region_id               = "aws-us-east-1"
  app_role_name           = "file_tunnel_app"
  auth_role_name          = "file_tunnel_auth"
  canonical_database_name = "canonical"
  auth_database_name      = "auth"
}
