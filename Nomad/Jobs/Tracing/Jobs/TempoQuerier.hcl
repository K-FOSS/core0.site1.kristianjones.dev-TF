job "tempo-querier" {
  datacenters = ["core0site1"]

  group "tempo-querier" {
    count = 3

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
      name = "tempo"
      port = "http"

      task = "tempo-querier"
      address_mode = "alloc"

      tags = ["coredns.enabled", "http.querier"]
    }

    service {
      name = "tempo"
      port = "grpc"

      task = "tempo-querier"
      address_mode = "alloc"

      tags = ["coredns.enabled", "grpc.querier", "_grpclb._tcp.grpc.querier"]
    }

    service {
      name = "tempo"
      
      port = "gossip"
      address_mode = "alloc"

      task = "tempo-querier"

      tags = ["coredns.enabled", "gossip.querier", "$${NOMAD_ALLOC_INDEX}.gossip.querier"]
    }

    task "tempo-querier" {
      driver = "docker"

      restart {
        attempts = 5
        delay = "60s"
      }

      config {
        image = "grafana/tempo:${Tempo.Version}"

        args = ["-search.enabled=true", "-config.file=/local/Tempo.yaml"]

        memory_hard_limit = 256

        logging {
          type = "loki"
          config {
            loki-url = "http://http.distributor.loki.service.kjdev:8080/loki/api/v1/push"

            loki-external-labels = "job=tempo,service=querier"
          }
        }
      }

      meta {
        TARGET = "querier"
      }

      resources {
        cpu = 128

        memory = 64
        memory_max = 128
      }

      template {
        data = <<EOF
${Tempo.YAMLConfig}
EOF

        destination = "local/Tempo.yaml"

        # Config Replacement
        change_mode = "signal"
        change_signal = "SIGHUP"
      }
    }
  }
}