job "network-dns-servicedns" {
  datacenters = ["core0site1"]

  group "servicedns-coredns-server" {
    count = 2

    spread {
      attribute = "$${node.unique.id}"
      weight = 100
    }

    network {
      mode = "cni/nomadcore1"

      port "dns" {
        to = 8060

        static = 8060

        host_network = "dns"
      }

      port "dnsnode" {
        to = 8060

        static = 8060

        host_network = "node"
      }

      port "health" {
        to = 8080
      }
    }

    service {
      name = "dns"
      port = "dns"

      task = "servicedns-coredns-server"
      address_mode = "alloc"

      tags = ["dns.service"]

      check {
        name = "CoreDNS DNS healthcheck"

        address_mode = "alloc"
        port = "health"
        type = "http"
        path = "/health"
        interval = "20s"
        timeout  = "5s"
      }
    }

    task "servicedns-coredns-server" {
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
        cpu = 128

        memory = 64
        memory_max = 128
      }
    }
  }
}