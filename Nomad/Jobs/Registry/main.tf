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

#
# Secrets
#

#
# Harbor Core
#
resource "random_password" "HarborCoreSecret" {
  length = 50
  special = true
}

#
# Harbor Job Service
#
resource "random_password" "HarborJobServiceSecret" {
  length = 50
  special = true
}

resource "random_password" "HarborRegistryServiceSecret" {
  length = 16
  special = false
}

resource "random_password" "HarborCSRFKeySecret" {
  length = 32
  special = false
}

resource "random_id" "HarborCoreKey" {
  byte_length = 16
}

locals {
  Harbor = {
    Secrets = {
      Core = random_password.HarborCoreSecret.result
      CoreSecretKey = random_id.HarborCoreKey.b64_std

      JobService = random_password.HarborJobServiceSecret.result

      Registry = random_password.HarborRegistryServiceSecret.result

      CSRFKey = random_password.HarborCSRFKeySecret.result
    }

    Version = "v2.4.1"
  }
}



resource "nomad_job" "HarborCoreJobFile" {
  jobspec = templatefile("${path.module}/Jobs/HarborCore.hcl", {
    EntryScript = file("${path.module}/Configs/HarborCore/Entry.sh")

    Harbor = {
      Secrets = local.Harbor.Secrets

      TLS = {
        CA = var.Harbor.TLS.CA

        Cert = var.Harbor.TLS.Core.Cert
        Key = var.Harbor.TLS.Core.Key
      }

      Database = var.Harbor.Database

      Config =  templatefile("${path.module}/Configs/HarborCore/app.conf", {
      })

      Version = local.Harbor.Version
    }
  })
}

resource "nomad_job" "HarborJobServiceJobFile" {
  jobspec = templatefile("${path.module}/Jobs/HarborJobService.hcl", {
    EntryScript = file("${path.module}/Configs/HarborJobService/Entry.sh")

    Harbor = {
      Secrets = local.Harbor.Secrets

      TLS = {
        CA = var.Harbor.TLS.CA

        Cert = var.Harbor.TLS.JobService.Cert
        Key = var.Harbor.TLS.JobService.Key
      }

      Config =  templatefile("${path.module}/Configs/HarborJobService/Config.yaml", {
      })

      Version = local.Harbor.Version
    }
  })
}

resource "nomad_job" "HarborPortalJobFile" {
  jobspec = templatefile("${path.module}/Jobs/HarborPortal.hcl", {
    EntryScript = file("${path.module}/Configs/HarborPortal/Entry.sh")

    Harbor = {
      TLS = {
        CA = var.Harbor.TLS.CA

        Cert = var.Harbor.TLS.Portal.Cert
        Key = var.Harbor.TLS.Portal.Key
      }

      Config =  templatefile("${path.module}/Configs/HarborPortal/NGINX.conf", {
      })

      Version = local.Harbor.Version
    }
  })
}

resource "nomad_job" "HarborRegistryJobFile" {
  jobspec = templatefile("${path.module}/Jobs/HarborRegistry.hcl", {
    EntryScript = file("${path.module}/Configs/HarborRegistry/Entry.sh")

    Harbor = {
      Secrets = local.Harbor.Secrets

      Registry = {
        Config = templatefile("${path.module}/Configs/HarborRegistry/Config.yaml", {
          S3 = var.Harbor.S3.Images
        })

        TLS = {
          CA = var.Harbor.TLS.CA

          Cert = var.Harbor.TLS.Registry.Cert
          Key = var.Harbor.TLS.Registry.Key
        }
      }

      RegistryCTL = {
        Config = templatefile("${path.module}/Configs/HarborRegistry/CTLConfig.yaml", {
          S3 = var.Harbor.S3.Images
        })

        TLS = {
          CA = var.Harbor.TLS.CA

          Cert = var.Harbor.TLS.RegistryCTL.Cert
          Key = var.Harbor.TLS.RegistryCTL.Key
        }

        EntryScript = file("${path.module}/Configs/HarborRegistry/CTLEntry.sh")
      }

      Version = local.Harbor.Version
    }
  })
}


#
# GitLab Registry API
#
resource "nomad_job" "HarborGitLabRegistryJobFile" {
  jobspec = templatefile("${path.module}/Jobs/HarborGitLabRegistry.hcl", {
    EntryScript = file("${path.module}/Configs/HarborRegistry/Entry.sh")

    Harbor = {
      Secrets = local.Harbor.Secrets

      Registry = {
        Config = templatefile("${path.module}/Configs/HarborGitLabRegistry/Config.yaml", {
          S3 = var.Harbor.S3.Images
        })

        TLS = {
          CA = var.Harbor.TLS.CA

          Cert = var.Harbor.TLS.GitLabRegistry.Cert
          Key = var.Harbor.TLS.GitLabRegistry.Key
        }
      }

      RegistryCTL = {
        Config = templatefile("${path.module}/Configs/HarborRegistry/CTLConfig.yaml", {
          S3 = var.Harbor.S3.Images
        })

        TLS = {
          CA = var.Harbor.TLS.CA

          Cert = var.Harbor.TLS.GitLabRegistryCTL.Cert
          Key = var.Harbor.TLS.GitLabRegistryCTL.Key
        }

        EntryScript = file("${path.module}/Configs/HarborRegistry/CTLEntry.sh")
      }

      Version = local.Harbor.Version
    }
  })
}

#
# Exporter
#

resource "nomad_job" "HarborExporterJobFile" {
  jobspec = templatefile("${path.module}/Jobs/HarborExporter.hcl", {
    EntryScript = file("${path.module}/Configs/HarborExporter/Entry.sh")

    Harbor = {
      Secrets = local.Harbor.Secrets

      Database = var.Harbor.Database

      TLS = {
        CA = var.Harbor.TLS.CA

        Cert = var.Harbor.TLS.Exporter.Cert
        Key = var.Harbor.TLS.Exporter.Key
      }

      Version = local.Harbor.Version
    }
  })
}

#
# ChartMuseum
#

resource "nomad_job" "HarborChartMuseumJobFile" {
  jobspec = templatefile("${path.module}/Jobs/ChartMuseum.hcl", {
    EntryScript = file("${path.module}/Configs/ChartMuseum/Entry.sh")

    ChartMuseum = {
      Secrets = local.Harbor.Secrets

      S3 = var.Harbor.S3.Charts

      Database = var.Harbor.Database

      TLS = {
        CA = var.Harbor.TLS.CA

        Cert = var.Harbor.TLS.ChartMuseum.Cert
        Key = var.Harbor.TLS.ChartMuseum.Key
      }

      Version = local.Harbor.Version
    }
  })
}
