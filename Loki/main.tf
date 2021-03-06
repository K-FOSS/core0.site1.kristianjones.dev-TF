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

locals {
  LOKI_TARGETS = tomap({
    Distributor = {
      name = "distributor"
      count = 3

      resources = {
        cpu = 128
        memory = 256
        memory_max = 256
      }
    },
    Ingester = {
      name = "ingester"
      count = 3
    
      resources = {
        cpu = 64
        memory = 64
        memory_max = 128
      }
    }, 
    Querier = {
      name = "querier"
      count = 3

      resources = {
        cpu = 128
        memory = 256
        memory_max = 256
      }
    },
    IndexGateway = {
      name = "index-gateway"
      count = 3

      resources = {
        cpu = 128
        memory = 256
        memory_max = 256 
      }
    }, 
    Compactor = {
      name = "compactor"
      count = 1

      resources = {
        cpu = 10
        memory = 32
        memory_max = 128
      }
    },
    QueryFrontend = {
      name = "query-frontend"
      count = 3

      resources = {
        cpu = 128
        memory = 32
        memory_max = 128
      }
    },
    QueryScheduler = {
      name = "query-scheduler"
      count = 3

      resources = {
        cpu = 128
        memory = 64
        memory_max = 128
      }
    }
  })
}