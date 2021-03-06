job "network-dns-rns" {
  datacenters = ["core0site1"]

  priority = 100

  group "rns-coredns-server" {
    count = 2

    restart {
      attempts = 20
      delay = "60s"
    }

    spread {
      attribute = "$${node.unique.id}"
      weight = 100
    }

    network {
      mode = "cni/nomadcore1"

      port "dns" {
        to = 53

        static = 53

        host_network = "dns"
      }

      port "dnsnode" {
        to = 53

        static = 53

        host_network = "node"
      }

      port "health" {
        to = 8080
      }

      port "pdns" {
        to = 9053
      }

      port "redis" { 
        to = 6379
      }

      dns {
        servers = [
          "172.16.51.1",
          "172.16.52.1",
          "172.18.0.10"
        ]
      }
    }

    service {
      name = "dns"
      port = "redis"

      task = "rns-dns-redis-cache"
      address_mode = "alloc"

      tags = ["coredns.enabled", "cache.rns"]
    }

    task "rns-dns-redis-cache" {
      driver = "docker"

      lifecycle {
        hook = "prestart"
        sidecar = true
      }

      config {
        image = "redis:latest"
      }

      resources {
        cpu = 64
        memory = 16
        memory_max = 32
      }
    }

    service {
      name = "dns"
      port = "dns"

      task = "rns-coredns-server"
      address_mode = "alloc"

      tags = ["dns.rns"]

      check {
        name = "CoreDNS DNS healthcheck"

        address_mode = "alloc"
        port = "health"
        type = "http"
        path = "/health"
        interval = "30s"
        timeout  = "5s"
        
        check_restart {
          limit = 3
          grace = "60s"
          ignore_warnings = false
        }
      }
    }

    service {
      name = "dns"
      port = "pdns"

      task = "rns-pdns-server"
      address_mode = "alloc"

      tags = ["coredns.enabled", "pdns.rns"]
    }


    task "rns-pdns-server" {
      driver = "docker"

      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      config {
        image = "powerdns/pdns-auth-master:latest"

        ports = ["pdns"]

        args = ["--config-dir=/local/"]
      }

      resources {
        cpu = 32
        memory = 128
        memory_max = 256
      }

      template {
        data = <<EOH
${PowerDNS.Config}
EOH

        destination = "local/pdns.conf"
      }
    }

    task "rns-coredns-server" {
      driver = "docker"

      config {
        image = "kristianfjones/coredns-docker:core0"

        ports = ["dns", "dnsnode"]

        memory_hard_limit = 256

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
        cpu = 32
        memory = 128
        memory_max = 256
      }
    }
  }
}