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
  full_name = "isc-projects/kea"
}

data "http" "PSQLFile" {
  url = "https://raw.githubusercontent.com/isc-projects/kea/Kea-2.0.0/src/share/database/scripts/pgsql/dhcpdb_create.pgsql"
}

#
# DHCP4
#

# resource "nomad_job" "KeaDHCP4" {
#   jobspec = templatefile("${path.module}/Jobs/KeaDHCP4.hcl", {
#     PSQL_INIT = data.http.PSQLFile.body
#     Database = var.Database

#     DHCP4 = {
#       Config = templatefile("${path.module}/Configs/KeaDHCP4/DHCP4.jsonc", {
#         Database = var.Database
#       })
#     }
#   })
# }

#
# DHCP6
#

# resource "nomad_job" "KeaDHCP4" {
#   jobspec = templatefile("${path.module}/Jobs/KeaDHCP4.hcl", {
#     PSQL_INIT = data.http.PSQLFile.body
#     Database = var.Database

#     DHCP4 = {
#       Config = templatefile("${path.module}/Configs/KeaDHCP4/DHCP4.jsonc", {
#         Database = var.Database
#       })
#     }
#   })
# }

#
# NetConf
#

# resource "nomad_job" "KeaNetConf" {
#   jobspec = templatefile("${path.module}/Jobs/KeaNetConf.hcl", {
#     PSQL_INIT = data.http.PSQLFile.body
#     Database = var.Database

#     DHCP4 = {
#       Config = templatefile("${path.module}/Configs/KeaNetConf/NetConf.jsonc", {
#         Database = var.Database
#       })
#     }
#   })
# }

#
# Kea Control Agent
#
# resource "nomad_job" "KeaCA" {
#   jobspec = templatefile("${path.module}/Jobs/KeaCA.hcl", {
#     PSQL_INIT = data.http.PSQLFile.body
#     Database = var.Database

#     DHCP4 = {
#       Config = templatefile("${path.module}/Configs/KeaCA/KeaCA.jsonc", {
#         Database = var.Database
#       })
#     }
#   })
# }
 
resource "nomad_job" "KeaDHCPJobFile" {
  jobspec = templatefile("${path.module}/Jobs/KeaDHCP.hcl", {
    PSQL_INIT = data.http.PSQLFile.body
    Database = var.Database

    DHCP4 = {
      Config = templatefile("${path.module}/Configs/KeaDHCP4/DHCP4.jsonc", {
        Database = var.Database
      })
    }

    DDNS = {
      Config = templatefile("${path.module}/Configs/KeaDDNS/DDNS.jsonc", {
        Database = var.Database
      })
    }

    DHCP6 = {
      Config = templatefile("${path.module}/Configs/KeaDHCP6/DHCP6.jsonc", {
        Database = var.Database
      })
    }

    KeaControlAgent = {
      Config = templatefile("${path.module}/Configs/KeaCA/KeaCA.jsonc", {})
    }

    NetConf = {
      Config = templatefile("${path.module}/Configs/KeaNetConf/NetConf.jsonc", {})
    }

    KeaCTRL = {
      Config = templatefile("${path.module}/Configs/keactrl.conf", {})
    }

    EntryScript = templatefile("${path.module}/Configs/entry.sh", {})
  })
}