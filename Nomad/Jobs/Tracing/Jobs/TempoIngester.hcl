job "tempo-ingester" {
  datacenters = ["core0site1"]

  group "tempo-ingester" {
    count = 3

    spread {
      attribute = "$${node.unique.id}"
      weight = 100
    }

    network {
      mode = "cni/nomadcore1"

      port "http" {
        to = 8080
      }

      port "grpc" { 
        to = 8085
      }

      port "gossip" { 
        to = 8090
      }
    }

    service {
      name = "tempo"
      port = "http"

      task = "tempo-ingester"
      address_mode = "alloc"

      tags = ["$${NOMAD_ALLOC_INDEX}", "coredns.enabled", "http.ingester"]
    }

    service {
      name = "tempo"
      port = "grpc"

      task = "tempo-ingester"
      address_mode = "alloc"

      tags = ["$${NOMAD_ALLOC_INDEX}", "coredns.enabled", "grpc.ingester"]
    }

    service {
      name = "tempo"
      
      port = "gossip"
      address_mode = "alloc"

      task = "tempo-ingester"

      tags = ["coredns.enabled", "gossip.ingester", "$${NOMAD_ALLOC_INDEX}.gossip.ingester"]
    }

    task "tempo-ingester" {
      driver = "docker"

      restart {
        attempts = 5
        delay = "60s"
      }

      config {
        image = "grafana/tempo:${Tempo.Version}"

        args = ["-search.enabled=true", "-config.file=/local/Tempo.yaml"]

        mount {
          type = "tmpfs"
          target = "/var/tempo/wal"
          readonly = false
          tmpfs_options = {
            size = 100000
          }
        }

        logging {
          type = "loki"
          config {
            loki-url = "http://http.distributor.loki.service.kjdev:8080/loki/api/v1/push"

            loki-external-labels = "job=tempo,service=ingester"
          }
        }
      }

      meta {
        TARGET = "ingester"
      }

      resources {
        cpu = 64
        memory = 128
      }

      template {
        data = <<EOF
${Tempo.YAMLConfig}
EOF

        destination = "local/Tempo.yaml"
      }

      template {
        data = <<EOF
overrides:
  "single-tenant":
    search_tags_allow_list:
      - "instance"
    ingestion_rate_strategy: "local"
    ingestion_rate_limit_bytes: 15000000
    ingestion_burst_size_bytes: 20000000
    max_traces_per_user: 10000
    max_global_traces_per_user: 0
    max_bytes_per_trace: 50000
    max_search_bytes_per_trace: 0
    block_retention: 0s
EOF

        destination = "local/overrides.yaml"
      }
    }
  }
}