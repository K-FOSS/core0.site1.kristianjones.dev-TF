job "gitlab-praefect" {
  datacenters = ["core0site1"]

  priority = 90

  #
  # GitLab Gitaly
  #
  group "gitlab-praefect" {
    count = 2

    spread {
      attribute = "$${node.unique.id}"
      weight = 100
    }

    network {
      mode = "cni/nomadcore1"

      port "http" { 
        to = 8080
      }

      port "metrics" { 
        to = 9000
      }

      dns {
        servers = [
          "10.1.1.53",
          "10.1.1.10",
          "10.1.1.13",
          "172.18.0.10"
        ]
      }
    }

    service {
      name = "gitlab"
      port = "http"

      task = "gitlab-praefect-server"
      address_mode = "alloc"

      tags = ["coredns.enabled", "http.praefect"]

      check {
        name = "tcp_validate"

        type = "tcp"

        port = "http"
        address_mode = "alloc"

        initial_status = "passing"

        interval = "30s"
        timeout  = "10s"

        check_restart {
          limit = 6
          grace = "120s"
          ignore_warnings = true
        }
      }
    }

    task "gitlab-praefect-server" {
      driver = "docker"

      config {
        image = "${Image.Repo}/gitaly:${Image.Tag}"

        memory_hard_limit = 512

        #
        # TODO: Fine tune this?
        #
        mount {
          type = "tmpfs"
          target = "/app/tmp"
          readonly = false
          tmpfs_options = {
            size = 100000
          }
        }

        logging {
          type = "loki"
          config {
            loki-url = "http://http.distributor.loki.service.kjdev:8080/loki/api/v1/push"

            loki-external-labels = "job=gitlab,service=praefect"
          }
        }
      }

      env {
        PRAEFECT_CONFIG_FILE = "/local/Config.toml"

        USE_PRAEFECT_SERVICE = "1"
        PRAEFECT_AUTO_MIGRATE = "1"
      }

      resources {
        cpu = 64

        memory = 64
        memory_max = 512
      }

      template {
        data = <<EOF
${Praefect.Config}
EOF

        destination = "local/Config.toml"
      }

      #
      # Shared Secrets
      #

      template {
        data = "${Secrets.WorkHorse}"

        destination = "secrets/.gitlab_workhorse_secret"

        change_mode = "noop"
      }

      template {
        data = "${Secrets.Shell}"

        destination = "secrets/.gitlab_shell_secret"

        change_mode = "noop"
      }

      template {
        data = "${Secrets.KAS}"

        destination = "secrets/.gitlab_kas_secret"

        change_mode = "noop"
      }
    }
  }
}