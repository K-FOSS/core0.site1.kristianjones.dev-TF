job "network-dns-rns" {
  datacenters = ["core0site1"]

  group "rns-coredns-server" {
    count = 2

    spread {
      attribute = "$${node.unique.id}"
      weight = 100
    }

    network {
      mode = "cni/nomadcore1"

      port "dns" {
        to = 8053

        static = 53

        host_network = "dns"
      }

      port "health" {
        to = 8080
      }
    }

    service {
      name = "dns"
      port = "dns"

      task = "rns-coredns-server"
      address_mode = "alloc"

      tags = ["$${NOMAD_ALLOC_INDEX}", "dns.rns"]

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

    task "rns-coredns-server" {
      driver = "docker"

      config {
        image = "kristianfjones/coredns-docker:core0"

        args = ["-conf=/local/Corefile"]
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
        cpu = 64
        memory = 128
        memory_max = 128
      }
    }
  }
}