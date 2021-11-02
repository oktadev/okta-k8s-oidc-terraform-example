variable "base_url" {
  description = "The Okta base URL. Example: okta.com, oktapreview.com, etc. This is the domain part of your Okta org URL"
}
variable "org_name" {
  description = "The Okta org name. This is the part before the domain in your Okta org URL"
}
variable "api_token" {
  type        = string
  description = "The Okta API token, this will be read from environment variable (TF_VAR_api_token) for security"
  sensitive   = true
}


# Enable and configure the Okta provider
terraform {
  required_providers {
    okta = {
      source  = "okta/okta"
      version = "~> 3.15"
    }
  }
}

provider "okta" {
  org_name  = var.org_name
  base_url  = var.base_url
  api_token = var.api_token
}


# Setup OKTA groups
resource "okta_group" "k8s_admin" {
  name        = "k8s-admins"
  description = "Users who can access k8s cluster as admins"
}

resource "okta_group" "k8s_restricted_users" {
  name        = "k8s-restricted-users"
  description = "Users who can only view pods and services in default namespace"
}

# Assign users to the groups
data "okta_user" "admin" {
  search {
    name  = "profile.email"
    value = "<your_admin_user_email>"
  }
}

resource "okta_group_memberships" "admin_user" {
  group_id = okta_group.k8s_admin.id
  users = [
    data.okta_user.admin.id
  ]
}

data "okta_user" "restricted_user" {
  search {
    name  = "profile.email"
    value = "<another_user_email>"
  }
}

resource "okta_group_memberships" "restricted_user" {
  group_id = okta_group.k8s_restricted_users.id
  users = [
    data.okta_user.restricted_user.id
  ]
}


# Create an OIDC application

resource "okta_app_oauth" "k8s_oidc" {
  label                      = "k8s OIDC"
  type                       = "native" # this is important
  token_endpoint_auth_method = "none"   # this sets the client authentication to PKCE
  grant_types = [
    "authorization_code"
  ]
  response_types = ["code"]
  redirect_uris = [
    "http://localhost:8000",
  ]
  post_logout_redirect_uris = [
    "http://localhost:8000",
  ]
  lifecycle {
    ignore_changes = [groups]
  }
}

output "k8s_oidc_client_id" {
  value = okta_app_oauth.k8s_oidc.client_id
}

# Assign groups to the OIDC application
resource "okta_app_group_assignments" "k8s_oidc_group" {
  app_id = okta_app_oauth.k8s_oidc.id
  group {
    id = okta_group.k8s_admin.id
  }
  group {
    id = okta_group.k8s_restricted_users.id
  }
}

# Create an authorization server

resource "okta_auth_server" "oidc_auth_server" {
  name      = "k8s-auth"
  audiences = ["http:://localhost:8000"]
}

output "k8s_oidc_issuer_url" {
  value = okta_auth_server.oidc_auth_server.issuer
}

# Add claims to the authorization server

resource "okta_auth_server_claim" "auth_claim" {
  name                    = "groups"
  auth_server_id          = okta_auth_server.oidc_auth_server.id
  always_include_in_token = true
  claim_type              = "IDENTITY"
  group_filter_type       = "STARTS_WITH"
  value                   = "k8s-"
  value_type              = "GROUPS"
}

# Add policy and rule to the authorization server

resource "okta_auth_server_policy" "auth_policy" {
  name             = "k8s_policy"
  auth_server_id   = okta_auth_server.oidc_auth_server.id
  description      = "Policy for allowed clients"
  priority         = 1
  client_whitelist = [okta_app_oauth.k8s_oidc.id]
}

resource "okta_auth_server_policy_rule" "auth_policy_rule" {
  name           = "AuthCode + PKCE"
  auth_server_id = okta_auth_server.oidc_auth_server.id
  policy_id      = okta_auth_server_policy.auth_policy.id
  priority       = 1
  grant_type_whitelist = [
    "authorization_code"
  ]
  scope_whitelist = ["*"]
  group_whitelist = ["EVERYONE"]
}
