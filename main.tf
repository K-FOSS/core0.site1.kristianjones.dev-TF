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
  }
}

#
# Hashicorp Vault
#

module "Vault" {
  source = "./Vault"

  Pomerium = {
    VaultPath = module.Consul.Pomerium.OIDVaultPath
  }
}

#
# Hashicorp Consul
#

module "Consul" {
  source = "./Consul"

  Patroni = {
    Prefix = "patroninew"
    ServiceName = "patroninew"
  }

  Cortex = {
    Prefix = "cortex"
  }

  Loki = {
    Prefix = "loki"
  }
}

#
# Minio S3 Storage Modules
#

#
# Grafana Cortex
#

module "CortexBucket" {
  source = "./Minio"

  Connection = {
    Hostname = "core0.site1.kristianjones.dev"
    Port = 9000
  }

  Credentials = module.Vault.Minio
}

module "LokiBucket" {
  source = "./Minio"

  Connection = {
    Hostname = "core0.site1.kristianjones.dev"
    Port = 9000
  }

  Credentials = module.Vault.Minio
}


#
# Databases
#


#
# Grafana Database 
#

module "GrafanaDatabase" {
  source = "./Database"

  Credentials = module.Vault.Database
}

#
# Authentik Database
#
module "AuthentikDatabase" {
  source = "./Database"

  Credentials = module.Vault.Database
}

#
# CoTurn
#

module "CoTurnDatabase" {
  source = "./Database"

  Credentials = module.Vault.Database
}


#
# Hashicorp Nomad
#

module "Cortex" {
  source = "./Cortex"
}

module "Loki" {
  source = "./Loki"
}

module "Nomad" {
  source = "./Nomad"

  #
  # Bitwarden
  #

  Bitwarden = {
    Database = {
      Hostname = "master.patroninew.service.kjdev"

      Username = module.Vault.BitwardenDB.data["username"]
      Password = module.Vault.BitwardenDB.data["password"]

      Database = "bitwarden"
    }
  }

  #
  # Caddy Web Ingress
  #

  Ingress = {
    Cloudflare = {
      Token = module.Vault.Cloudflare.data["Token"]
    }

    Consul = {
      Token = module.Vault.Caddy.data["CONSUL_HTTP_TOKEN"]
      EncryptionKey = module.Vault.Caddy.data["CADDY_CLUSTERING_CONSUL_AESKEY"]
    }
  }

  #
  # Grafana
  #

  Grafana = {
    Database = module.GrafanaDatabase.Database
  }

  #
  # AAA
  #

  #
  # Authentik
  #

  Authentik = {
    Database = module.AuthentikDatabase.Database
  }

  #
  # Patroni
  #
  Patroni = {
    Consul = module.Consul.Patroni
  }

  #
  # Pomerium
  #
  Pomerium = {
    OpenID = module.Vault.Pomerium
  }

  #
  # CoTurn
  #
  CoTurn = {
    CoTurn = {
      Realm = "kristianjones.dev"
    }

    Database = module.CoTurnDatabase.Database
  }

  Metrics = {
    Cortex = {
      Consul = module.Consul.Cortex

      Targets = module.Cortex.Targets

      S3 = module.CortexBucket
    }

    Loki = {
      Consul = module.Consul.Loki

      Targets = module.Loki.Targets

      S3 = module.LokiBucket
    }
  }

  Storage = {
    NAS = {
      Hostname = "172.16.51.21"

      Admin = {
        Hostname = "172.16.20.21"
      }

      Password = module.Vault.NAS.Password
    }
  }
} 