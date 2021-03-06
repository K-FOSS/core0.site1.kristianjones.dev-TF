terraform {
  required_providers {
    #
    # Hashicorp Vault
    #
    # Docs: https://registry.terraform.io/providers/hashicorp/vault/latest/docs
    #
    nomad = {
      source = "hashicorp/nomad"
      version = "1.4.15"
    }

    #
    # GitHub Provider
    #
    # Used to fetch the latest PSQL file
    #
    # Docs: https://registry.terraform.io/providers/integrations/github/latest
    #
    github = {
      source = "integrations/github"
      version = "4.17.0"
    }

    #
    # Hashicorp Terraform HTTP Provider
    #
    # Docs: https://registry.terraform.io/providers/hashicorp/http/latest/docs
    #
    http = {
      source = "hashicorp/http"
      version = "2.1.0"
    }

    #
    # Randomness
    #
    # TODO: Find a way to best improve true randomness?
    #
    # Docs: https://registry.terraform.io/providers/hashicorp/random/latest/docs
    #
    random = {
      source = "hashicorp/random"
      version = "3.1.0"
    }
  }
}

data "github_repository" "Repo" {
  full_name = "opf/openproject"
}

data "github_release" "Release" {
  repository  = data.github_repository.Repo.name
  owner       = split("/", data.github_repository.Repo.full_name)[0]
  retrieve_by = "latest"
}

resource "random_password" "OpenProjectSecret" {
  length = 50
  special = true
}

locals {
  OpenProject = {
    Database = var.Database

    OpenID = var.OpenID

    S3 = var.S3

    Admin = var.Admin

    SMTP = var.SMTP

    Version = split("v", data.github_release.Release.release_tag)[1]
  }
}

#
# Secrets
#



resource "random_password" "NetboxRedisPassword" {
  length = 16
  special = true
}

resource "random_password" "NetboxRedisCachePassword" {
  length = 16
  special = true
}

#
# OpenProject Server
#
resource "nomad_job" "OpenProjectServerJobFile" {
  jobspec = templatefile("${path.module}/Jobs/OpenProjectServer.hcl", local.OpenProject)
}

#
# OpenProject Proxy
#

resource "nomad_job" "OpenProjectProxyJobFile" {
  jobspec = templatefile("${path.module}/Jobs/OpenProjectProxy.hcl", local.OpenProject)
}

#
# OpenProject Worker
#

resource "nomad_job" "OpenProjectWorkerJobFile" {
  jobspec = templatefile("${path.module}/Jobs/OpenProjectWorker.hcl", local.OpenProject)
}

#
# OpenProject CRON
#

resource "nomad_job" "OpenProjectCRONJobFile" {
  jobspec = templatefile("${path.module}/Jobs/OpenProjectCRON.hcl", local.OpenProject)
}
