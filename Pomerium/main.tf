terraform {
  required_providers {
    #
    # Hashicorp Consul
    #
    # Docs: https://registry.terraform.io/providers/hashicorp/consul/latest/docs
    #
    consul = {
      source = "hashicorp/consul"
      version = "2.13.0"
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

resource "random_string" "CookieSecret" {
  length           = 32
  special          = true
}

resource "random_string" "SharedSecret" {
  length           = 32
  special          = true
}

locals {
  Secrets = {
    CookieSecret = base64encode(random_string.CookieSecret.result)
    SharedSecret = base64encode(random_string.SharedSecret.result)
  }
}