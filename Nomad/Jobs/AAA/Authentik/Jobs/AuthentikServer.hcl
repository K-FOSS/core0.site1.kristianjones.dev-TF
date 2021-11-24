job "authentik-server" {
  datacenters = ["core0site1"]

  group "auth-server" {
    count = 3

    spread {
      attribute = "$${node.unique.id}"
      weight = 100
    }

    update {
      max_parallel = 1

      health_check = "checks"
      
      min_healthy_time = "30s"

      healthy_deadline = "3m"

      progress_deadline = "8m"
    }

    network {
      mode = "cni/nomadcore1"

      port "http" { 
        to = 9000
      }

      port "metrics" { 
        to = 9300
      }

      dns {
        servers = [
          "10.1.1.53",
          "172.16.0.1"
        ]
      }
    }

    service {
      name = "authentik"
      port = "metrics"

      task = "authentik-server"
      address_mode = "alloc"

      tags = ["$${NOMAD_ALLOC_INDEX}", "coredns.enabled", "metrics.server"]

      #
      # Liveness check
      #
      check {
        name = "HTTP Check"
        type = "http"

        address_mode = "alloc"
        port = "http"

        path     = "/-/health/live/"
        interval = "10s"
        timeout  = "3s"

        check_restart {
          limit = 12
          grace = "60s"
          ignore_warnings = false
        }
      }
    }

    service {
      name = "authentik"
      port = "http"

      task = "authentik-server"
      address_mode = "alloc"

      tags = ["$${NOMAD_ALLOC_INDEX}", "coredns.enabled", "http.server"]

      #
      # Liveness check
      #
      check {
        name = "HTTP Check"
        type = "http"

        address_mode = "alloc"
        port = "http"

        path     = "/-/health/live/"
        interval = "10s"
        timeout  = "3s"

        check_restart {
          limit = 12
          grace = "60s"
          ignore_warnings = false
        }
      }
    }

    task "authentik-server" {
      driver = "docker"

      config {
        image = "ghcr.io/goauthentik/server:${Version}"

        args = ["server"]

        logging {
          type = "loki"
          config {
            loki-url = "http://http.distributor.loki.service.kjdev:8080/loki/api/v1/push"

            loki-external-labels = "job=cache,service=web"
          }
        }
      }

      env {
        #
        # Database
        #
        AUTHENTIK_POSTGRESQL__HOST = "${Database.Hostname}"
        AUTHENTIK_POSTGRESQL__PORT = "${Database.Port}"

        AUTHENTIK_COOKIE_DOMAIN = "auth.kristianjones.dev"

        AUTHENTIK_EMAIL__USE_TLS = "true"
      }

      template {
        data = <<EOH
#
# Cache
#
AUTHENTIK_REDIS__HOST="redis.authentik.service.dc1.kjdev"

#
# Database
#
AUTHENTIK_POSTGRESQL__NAME="${Database.Database}"

# Database Credentials
AUTHENTIK_POSTGRESQL__USER="${Database.Username}"
AUTHENTIK_POSTGRESQL__PASSWORD="${Database.Password}"

#
# Secrets
#
AUTHENTIK_SECRET_KEY="${Authentik.SecretKey}"

#
# Email
#
AUTHENTIK_EMAIL__HOST="${SMTP.Server}"
AUTHENTIK_EMAIL__PORT="${SMTP.Port}"

AUTHENTIK_EMAIL__FROM="${SMTP.Username}"
AUTHENTIK_EMAIL__USERNAME="${SMTP.Username}"
AUTHENTIK_EMAIL__PASSWORD="${SMTP.Password}"
EOH

        destination = "secrets/file.env"
        env = true
      }

      resources {
        cpu = 256

        memory = 1024
      }
    }
  }
}