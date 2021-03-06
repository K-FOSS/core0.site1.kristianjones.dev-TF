job "network-dns-pns" {
  datacenters = ["core0site1"]

  group "pns-coredns-server" {
    count = 2

    spread {
      attribute = "$${node.unique.id}"
      weight = 100
    }

    network {
      mode = "cni/nomadcore1"

      port "dns" {
        to = 8070

        static = 8070

        host_network = "dns"
      }

      port "dnsnode" {
        to = 8070

        static = 8070

        host_network = "node"
      }

      port "health" {
        to = 8080
      }
    }

    service {
      name = "dns"
      port = "dns"

      task = "pns-coredns-server"
      address_mode = "alloc"

      tags = ["dns.ns"]

      check {
        name = "CoreDNS DNS healthcheck"

        address_mode = "alloc"
        port = "health"
        type = "http"
        path = "/health"
        interval = "20s"
        timeout  = "5s"
        
        check_restart {
          limit = 3
          grace = "60s"
          ignore_warnings = false
        }
      }
    }

    task "pns-coredns-server" {
      driver = "docker"

      config {
        image = "kristianfjones/coredns-docker:core0"

        args = ["-conf=/local/Corefile"]

        logging {
          type = "loki"
          config {
            loki-url = "http://http.distributor.loki.service.kjdev:8080/loki/api/v1/push"

            loki-external-labels = "job=dns,service=publicns"
          }
        }
      }

      template {
        data = <<EOF
${CoreFile}
EOF

        destination = "local/Corefile"
      }

      template {
        data = <<EOF
${PluginsConfig}
EOF

        destination = "local/plugin.cfg"
      }

      resources {
        cpu = 128

        memory = 64
        memory_max = 128
      }
    }
  }
}