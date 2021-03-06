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
  full_name = "home-assistant/core"
}

data "github_release" "Release" {
  repository  = data.github_repository.Repo.name
  owner       = split("/", data.github_repository.Repo.full_name)[0]
  retrieve_by = "latest"
}

# resource "nomad_volume" "Volume" {
#   type                  = "csi"
#   plugin_id             = "truenas"
#   volume_id             = "homeassistant-data"
#   name                  = "homeassistant-data"
#   external_id           = "homeassistant-data"

#   capability {
#     access_mode     = "multi-node-multi-writer"
#     attachment_mode = "file-system"
#   }

#   deregister_on_destroy = true

#   mount_options {
#     fs_type = "nfs"
#     mount_flags = ["nolock", "nfsvers=4"]
#   }

#   context = {
#     node_attach_driver = "nfs"
#     provisioner_driver = "freenas-nfs"
#     server             = "172.16.51.21"
#     share              = "/mnt/Site1.NAS1.Pool1/CSI/vols/homeassistant-data"
#   }
# }

# resource "nomad_job" "HomeAssistant" {
#   jobspec = templatefile("${path.module}/Job.hcl", {
#     Volume = nomad_volume.Volume

#     MQTT = var.MQTT

#     TLS = var.TLS

#     PrepareScript = templatefile("${path.module}/Configs/Install.sh", {})

#     SecretsYAML = templatefile("${path.module}/Configs/HASS/secrets.template.yaml", {
#       Database = var.Database

#       MQTT = var.MQTT

#       Secrets = var.Secrets
#     })

#     Database = var.Database

#     Version = data.github_release.Release.release_tag
#   })
# }