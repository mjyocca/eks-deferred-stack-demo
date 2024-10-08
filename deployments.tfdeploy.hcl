# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Configure an identity token for OIDC authenticaiton with AWS
identity_token "aws" {
  audience = ["aws.workload.identity"]
}

# Source secrets from HCP Terraform variable set
store "varset" "tokens" {
  id       = "varset-Uq2aGQdKgxk7cDRX"
  category = "terraform"
}

# Define variables that are reused across the deployments
locals {
  kubernetes_version  = "1.30"
  default_tags        = { stacks-preview-example = "eks-deferred-stack-demo" }
  tfe_organization    = "hashicorp"
  tfe_project_name    = "Default Project"
  github_username     = "mjyocca"
  repo_name           = "mjyocca/local-tf-stack-pet-nulls"
  oauth_client_name   = "Github.com (Stacks Local)"

  arn                 = "arn:aws:iam::112041562934:role/STACKS_OIDC_IDENTITY_ROLE"
}

deployment "development" {
  inputs = {
    cluster_name        = "stacks-development-demo"
    region              = "us-west-1"
    
    identity_token      = identity_token.aws.jwt

    kubernetes_version  = local.kubernetes_version
    role_arn            = local.arn
    default_tags        = local.default_tags
    github_username     = local.github_username
    repo_name           = local.repo_name
    oauth_client_name   = local.oauth_client_name
    tfe_organization    = local.tfe_organization
    tfe_project_name    = local.tfe_project_name
    tfe_token           = store.varset.tokens.local_tfe_token
  }
}

deployment "production" {
  inputs = {
    cluster_name        = "stacks-production-demo"
    region              = "us-east-1"

    identity_token      = identity_token.aws.jwt

    kubernetes_version  = local.kubernetes_version
    role_arn            = local.arn
    default_tags        = local.default_tags
    github_username     = local.github_username
    repo_name           = local.repo_name
    oauth_client_name   = local.oauth_client_name
    tfe_organization    = local.tfe_organization
    tfe_project_name    = local.tfe_project_name
    tfe_token           = store.varset.tokens.local_tfe_token
  }
}

orchestrate "auto_approve" "safe_plans" {
  # Ensure that no resources are being removed
  check {
    condition = context.plan.changes.remove == 0
    reason    = "Plan has ${context.plan.changes.remove} resources to be destroyed."
  }

  # Ensure that the deployment is not production
  check {
    condition = context.plan.deployment != deployment.production
    reason    = "Production plans are not eligible for auto_approve."
  }
}
