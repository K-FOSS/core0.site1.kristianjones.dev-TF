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

locals {
  HashUI = {
    Image = {
      Repo = ""

      Tag = ""
    }


  }
}

resource "nomad_job" "HashUIJobFile" {
  jobspec = templatefile("${path.module}/Jobs/Hash-UI.hcl", {
    HashUI = local.HashUI
  })
}