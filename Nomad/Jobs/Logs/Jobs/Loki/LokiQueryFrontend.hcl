job "loki-query-frontend" {
  datacenters = ["core0site1"]

  #
  # Loki Query Frontend
  #
  group "loki-query-frontend" {
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

      task = "loki-query-frontend"
      address_mode = "alloc"

      tags = ["coredns.enabled", "http.query-frontend"]

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

      task = "loki-query-frontend"
      address_mode = "alloc"

      tags = ["coredns.enabled", "grpc.query-frontend", "$${NOMAD_ALLOC_INDEX}.grpc.query-frontend", "_grpclb._tcp.grpc.query-frontend"]
    }

    service {
      name = "loki"
      
      port = "gossip"
      address_mode = "alloc"

      task = "loki-query-frontend"

      tags = ["coredns.enabled", "gossip.query-frontend", "$${NOMAD_ALLOC_INDEX}.gossip.query-frontend"]
    }

    task "loki-query-frontend" {
      driver = "docker"

      kill_timeout = 120

      restart {
        attempts = 5
        delay = "60s"
      }

      config {
        image = "grafana/loki:${Loki.Version}"

        args = ["-config.file=/local/Loki.yaml"]

        memory_hard_limit = 256
      }

      meta {
        TARGET = "query-frontend"

        REPLICAS = "3"
      }

      resources {
        cpu = 64

        memory = 64
        memory_max = 256
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