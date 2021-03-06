job "loki-ingester" {
  datacenters = ["core0site1"]

  #
  # Loki Ingester
  #
  group "loki-ingester" {
    count = 4

    spread {
      attribute = "$${node.unique.id}"
      weight = 100
    }

    network {
      mode = "cni/nomadcore1"

      port "http" {
        to = 8080

        host_network = "node"
      }

      port "grpc" { 
        to = 8085
      }

      port "gossip" { 
        to = 8090
      }

      dns {
        servers = [
          "10.1.1.53",
          "10.1.1.10",
          "10.1.1.13"
        ]
      }
    }

    service {
      name = "loki"
      port = "http"

      task = "loki-ingester"
      address_mode = "alloc"

      tags = ["$${NOMAD_ALLOC_INDEX}", "coredns.enabled", "http.ingester"]

      #
      # Liveness check
      #
      check {
        port = "http"
        address_mode = "alloc"

        type = "http"

        path = "/ready"
        interval = "15s"
        timeout  = "3s"

        check_restart {
          limit = 10
          grace = "10m"
        }
      }
    }

    service {
      name = "loki"
      port = "grpc"

      task = "loki-ingester"
      address_mode = "alloc"

      tags = ["coredns.enabled", "grpc.ingester", "$${NOMAD_ALLOC_INDEX}.grpc.ingester", "_grpclb._tcp.grpc.ingester"]
    }

    service {
      name = "loki"
      
      port = "gossip"
      address_mode = "alloc"

      task = "loki-ingester"

      tags = ["coredns.enabled", "gossip.ingester", "$${NOMAD_ALLOC_INDEX}.gossip.ingester"]
    }

    task "loki-ingester" {
      driver = "docker"

      kill_timeout = 120

      user = "root"

      restart {
        attempts = 5
        delay = "60s"
      }

      config {
        image = "grafana/loki:${Loki.Version}"

        args = ["-config.file=/local/Loki.yaml"]

        mount {
          type = "tmpfs"
          target = "/tmp/wal"
          readonly = false
          tmpfs_options = {
            size = 10240000000
          }
        }

        memory_hard_limit = 2048
      }

      meta {
        TARGET = "ingester"

        REPLICAS = "3"
      }

      resources {
        cpu = 64

        memory = 256
        memory_max = 2048
      }

      template {
        data = <<EOF
${Loki.YAMLConfig}
EOF

        destination = "local/Loki.yaml"
      }
    }
  }
}