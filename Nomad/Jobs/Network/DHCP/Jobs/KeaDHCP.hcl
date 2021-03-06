job "dhcp" {
  datacenters = ["core0site1"]

  group "dhcp" {
    count = 2

    network {
      mode = "cni/nomadcore1"

      port "dhcp" {
        to = 67

        static = 67

        host_network = "dns"
      }

      port "metrics" {
        to = 9547
      }

      port "controlagent" {
        to = 8000
      }
    }

    service {
      name = "dhcp"
      port = "dhcp"

      task = "kea-dhcp-server"
      address_mode = "alloc"

      tags = ["coredns.enabled"]

      check {
        name = "Kea Control Health healthcheck"

        address_mode = "alloc"
        port = 8000
        type = "tcp"
        interval = "20s"
        timeout  = "5s"
        
        check_restart {
          limit = 3
          grace = "60s"
          ignore_warnings = false
        }
      }
    }

    service {
      name = "dhcp-metrics"
      port = "metrics"

      task = "kea-dhcp-server"
      address_mode = "alloc"

      tags = ["coredns.enabled"]
    }

    task "dhcp-db" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      driver = "docker"

      config {
        image = "postgres:alpine3.14"

        command = "/usr/local/bin/psql"

        args = ["--file=/local/dhcp.psql", "--host=${Database.Hostname}", "--username=${Database.Username}", "--port=${Database.Port}", "${Database.Database}"]
      }

      env {
        PGPASSFILE = "/secrets/.pgpass"
      }

      template {
        data = <<EOH
${PSQL_INIT}
EOH

        destination = "local/dhcp.psql"
      }

      template {
        data = <<EOH
${Database.Hostname}:${Database.Port}:${Database.Database}:${Database.Username}:${Database.Password}
EOH

        perms = "600"

        destination = "secrets/.pgpass"
      }
    }

    task "kea-dhcp-server" {
      driver = "docker"

      config {
        image = "kristianfjones/kea:vps1-core"
        command = "/local/entry.sh"

        logging {
          type = "loki"
          config {
            loki-url = "http://http.distributor.loki.service.kjdev:8080/loki/api/v1/push"

            loki-external-labels = "job=dhcp,service=kea-dhcp4"
          }
        }
      }

      #
      # DHCP Config
      #

      # DHCP4
      template {
        data = <<EOF
${DHCP4.Config}
EOF

        destination = "local/DHCP4.jsonc"
      }

      # DHCP6
      template {
        data = <<EOF
${DHCP6.Config}
EOF

        destination = "local/DHCP6.jsonc"
      }

      # DDNS
      template {
        data = <<EOF
${DDNS.Config}
EOF

        destination = "local/DDNS.jsonc"
      }

      # NetConf
      template {
        data = <<EOF
${NetConf.Config}
EOF

        destination = "local/NetConf.jsonc"
      }

      #
      # Kea CTRL
      #

      # Kea CTRL Config
      template {
        data = <<EOF
${KeaCTRL.Config}
EOF

        destination = "local/keactrl.conf"
      }

      # Kea CTRL Agent Config
      template {
        data = <<EOF
${KeaControlAgent.Config}
EOF

        destination = "local/KeaCA.jsonc"
      }


      # Entrypoint Script
      template {
        data = <<EOF
${EntryScript}
EOF

        destination = "local/entry.sh"

        perms = "777"
      }

      resources {
        cpu = 32
        memory = 32
        memory_max = 64
      }
    }
  }
}