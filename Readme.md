# Terraform configuration for Okta OIDC server for Kubernetes

This is the required Terraform configuration to create an OIDC server to authenticate to Kubernetes API Server using Okta.

This full blog post is [here](https://developer.okta.com/blog/)

The configuration does the following

- Configure Okta Terraform provider
- Create Okta groups
- Assign users to the groups
- Create an Okta OIDC application
- Create an Okta authorization server
- Add claims to the authorization server
- Add policy and rule to the authorization server
