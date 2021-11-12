job "pomerium-authorize" {
  datacenters = ["core0site1"]

  group "pomerium-authorize" {
    count = 3

    network {
      mode = "cni/nomadcore1"

      port "https" {
        to = 443
      }

      port "metrics" {
        to = 9443
      }
    }

    service {
      name = "pomerium"
      port = "https"

      task = "pomerium-authorize-server"
      address_mode = "alloc"

      tags = ["$${NOMAD_ALLOC_INDEX}", "coredns.enabled", "https.authorize"]
    }

    task "pomerium-authorize-server" {
      driver = "docker"

      restart {
        attempts = 5
        delay = "60s"
      }

      config {
        image = "pomerium/pomerium:${Version}"

        args = ["-config=/local/Pomerium.yaml"]

        labels {
          job = "pomerium"
          service = "authorize"
        }
      }

      meta {
        SERVICE = "authorize"
      }

      template {
        data = <<EOF
${Config}
EOF

        destination = "local/Pomerium.yaml"

        change_mode = "signal"
        change_signal = "SIGUSR1"
      }

      #
      # Server TLS
      #

      template {
        data = <<EOF
${TLS.Server.CA}
EOF

        destination = "local/ServerCA.pem"
      }

      template {
        data = <<EOF
${TLS.Server.Cert}
EOF

        destination = "secrets/TLS/Server.pem"
      }

      template {
        data = <<EOF
${TLS.Server.Key}
EOF

        destination = "secrets/TLS/Server.key"
      }

      #
      # Metrics TLS
      #
      template {
        data = <<EOF
${TLS.Metrics.CA}
EOF

        destination = "local/MetricsServerCA.pem"
      }

      template {
        data = <<EOF
${TLS.Metrics.Cert}
EOF

        destination = "secrets/TLS/Metrics.pem"
      }

      template {
        data = <<EOF
${TLS.Metrics.Key}
EOF

        destination = "secrets/TLS/Metrics.key"
      }

      resources {
        cpu = 800
        memory = 256
      }
    }
  }
}