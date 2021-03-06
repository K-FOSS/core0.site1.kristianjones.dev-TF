job "cache-gitlab" {
  datacenters = ["core0site1"]

  group "gitlab-redis" {
    count = 1

    network {
      mode = "cni/nomadcore1"

      port "redis" { 
        to = 6379
      }
    }

    service {
      name = "gitlab"
      port = "redis"

      task = "gitlab-redis-server"
      address_mode = "alloc"

      tags = ["coredns.enabled", "redis"]

      check {
        name = "tcp_validate"

        type = "tcp"

        port = "redis"
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

    task "gitlab-redis-server" {
      driver = "docker"

      config {
        image = "redis:latest"
      }

      resources {
        cpu = 128
        memory = 128
        memory_max = 128
      }

      template {
        data = <<EOF
bind 0.0.0.0
port 6379
EOF

        destination = "local/redis.conf"
      }
    }
  }
}