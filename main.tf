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

  Tempo = {
    Prefix = "tempo"
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

#
# Grafana Loki
#

module "LokiBucket" {
  source = "./Minio"

  Connection = {
    Hostname = "core0.site1.kristianjones.dev"
    Port = 9000
  }

  Credentials = module.Vault.Minio
}

#
# Grafana Tempo
#

module "TempoBucket" {
  source = "./Minio"

  Connection = {
    Hostname = "core0.site1.kristianjones.dev"
    Port = 9000
  }

  Credentials = module.Vault.Minio
}

#
# NextCloud
# 
module "NextCloud" {
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
# Netbox
#
module "NetboxDatabase" {
  source = "./Database"

  Credentials = module.Vault.Database
}

#
# DHCP Database
#
module "DHCPDatabase" {
  source = "./Database"

  Credentials = module.Vault.Database
}

#
# NextCloud
#
module "NextCloudDatabase" {
  source = "./Database"

  Credentials = module.Vault.Database
}

#
# Tinkerbell
#

module "TinkerbellDatabase" {
  source = "./Database"

  Credentials = module.Vault.Database
}

#
# Tinkerbell
#
module "Tinkerbell" {
  source = "./Database"

  Credentials = module.Vault.Database
}

#
# Mattermost
#
module "MattermostDatabase" {
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

module "Tempo" {
  source = "./Tempo"
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

    Tempo = {
      Consul = module.Consul.Tempo

      Targets = module.Tempo.Targets

      S3 = module.TempoBucket
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

  Netbox = {
    Database = module.NetboxDatabase.Database

    Admin = {
      Username = "kjones"
      Email = "k@kristianjones.dev"
    }
  }

  DHCP = {
    Database = module.DHCPDatabase.Database
  }

  Mattermost = {
    Database = module.MattermostDatabase.Database
  }

  Tinkerbell = {
    Database = module.TinkerbellDatabase.Database
  }
} 