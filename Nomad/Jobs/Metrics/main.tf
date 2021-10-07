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
      version = "4.15.1"
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

resource "nomad_job" "Metrics" {
  jobspec = templatefile("${path.module}/Jobs/Metrics/Job.hcl", {
    Prometheus = {
      YAMLConfig = templatefile("${path.module}/Jobs/Metrics/Configs/Prometheus.yaml", {
        
      })

      Version = "v2.30.0"
    }

    Cortex = {
      Targets = var.Metrics.Cortex.Targets

      YAMLConfig = templatefile("${path.module}/Jobs/Metrics/Configs/Cortex.yaml", var.Cortex)

      Version = "master-3291733"
    }

    Loki = {
      Targets = var.Metrics.Loki.Targets

      YAMLConfig = templatefile("${path.module}/Jobs/Metrics/Configs/Loki.yaml", var.Loki)

      Version = "latest"
    }

    Tempo = {
      Targets = var.Metrics.Tempo.Targets

      YAMLConfig = templatefile("${path.module}/Jobs/Metrics/Configs/Tempo.yaml", var.Tempo)

      Version = "latest"
    }

    Vector = {
      YAMLConfig = templatefile("${path.module}/Jobs/Metrics/Configs/Vector.yaml", {  })
    }
  })
}