# Terraform configuration to set up Okta OIDC for Kubernetes API server

This repository contains Terraform configuration required to set up Okta OIDC server for using OIDC login for Kubernetes API server.

Please read [How to Secure Your Kubernetes Cluster with OpenID Connect and RBAC](http://developer.okta.com/blog/2021/11/08/k8s-api-server-oidc) to see how you can use Okta to secure your Kubernetes API server and use Terraform to setup the Okta OIDC server.

**Prerequisites:**

- An Okta account. You can sign up for a free account [here](https://developer.okta.com/signup/). If you like, you can use another OIDC provider or [Dex](https://github.com/dexidp/dex), and the steps should be similar.
- A Kubernetes cluster. I'm using [k3d](https://k3d.io/) to run a local [k3s](https://k3s.io/) cluster. You can use any Kubernetes distribution, including managed PaaS like Amazon EKS, AKS, and GKE, and so on.
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed on your machine.
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed on your machine. This is not required if you do the Okta configuration via the [Okta Admin Console](https://login.okta.com/) GUI.

## Getting started

Clone this repo

```
git clone https://github.com/oktadev/okta-k8s-oidc-terraform-example.git
```

You need to provide the input variables `org_name`, `base_url`, and `api_token`. Update these values in the file `okta.config.auto.tfvars`. For example, if the address of your Okta instance is `dev-1234.okta.com`, then your `org_name` would be `dev-1234`, and `base_url` would be everything that comes after the org name (e.g., okta.com).

Next, you will need to generate the `api-token` value. Log in to your Okta administrator console as a superuser and select **Security** > **API** > **Tokens (Tab)** from the navigation menu. Next, click the **Create Token** button, give your token a name, click **Create Token**, and copy the newly generated token. Save this in a separate `.tfvars` file excluded from Git or in an environment variable named `TF_VAR_api_token`.

The Okta provider is now configured and ready to go.

The Terraform configuration does the following

- Configure Okta Terraform provider
- Create Okta groups
- Assign users to the groups
- Create an Okta OIDC application
- Create an Okta authorization server
- Add claims to the authorization server
- Add policy and rule to the authorization server

### Create the Okta configurations using Terraform

First, run `terraform plan` to see the changes that will be made. Verify that the changes proposed by the `plan` make the changes you wanted, on the resources that you intended to modify. Then run `terraform apply` and type `yes` to apply the changes. You should see an output similar to this. You can also log in to the Okta Admin Console to verify the changes.

Copy the output values as you will need them for the next steps.

```bash
okta_group.k8s_admin: Creating...
okta_group.k8s_restricted_users: Creating...
okta_auth_server.oidc_auth_server: Creating...
okta_app_oauth.k8s_oidc: Creating...
okta_group.k8s_admin: Creation complete after 0s [id=00g2b0rmupxo1C1HW5d7]
okta_group.k8s_restricted_users: Creation complete after 0s [id=00g2b0q4zejpq6hbi5d7]
okta_group_memberships.restricted_user: Creating...
okta_group_memberships.admin_user: Creating...
okta_auth_server.oidc_auth_server: Creation complete after 1s [id=aus2b0ql0ihgilIh95d7]
okta_auth_server_claim.auth_claim: Creating...
okta_group_memberships.admin_user: Creation complete after 1s [id=00g2b0rmupxo1C1HW5d7]
okta_group_memberships.restricted_user: Creation complete after 1s [id=00g2b0q4zejpq6hbi5d7]
okta_app_oauth.k8s_oidc: Creation complete after 1s [id=0oa2b0qc0x38Xjxbk5d7]
okta_app_group_assignments.k8s_oidc_group: Creating...
okta_auth_server_policy.auth_policy: Creating...
okta_auth_server_claim.auth_claim: Creation complete after 0s [id=ocl2b0rc6ejmIO4KR5d7]
okta_app_group_assignments.k8s_oidc_group: Creation complete after 1s [id=0oa2b0qc0x38Xjxbk5d7]
okta_auth_server_policy.auth_policy: Creation complete after 1s [id=00p2b0qjjxsSz0Mya5d7]
okta_auth_server_policy_rule.auth_policy_rule: Creating...
okta_auth_server_policy_rule.auth_policy_rule: Creation complete after 1s [id=0pr2b0rgnfxjyu6cy5d7]

Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:

k8s_oidc_client_id = "0oa2b0qc0x38Xjxbk5d7"
k8s_oidc_issuer_url = "https://dev-xxxxxx.okta.com/oauth2/aus2b0ql0ihgilIh95d7"
```

You can run `terraform destroy` to revert the changes if required.

> **TIP**: You can use the `terraform import <resource_name.id>` command to import data and configuration from your Okta instance. Refer [these docs](https://registry.terraform.io/providers/okta/okta/latest/docs) for more information.

Please read [How to Secure Your Kubernetes Cluster with OpenID Connect and RBAC](http://developer.okta.com/blog/2021/11/08/k8s-api-server-oidc) to see how you can use this with Kubernetes.
