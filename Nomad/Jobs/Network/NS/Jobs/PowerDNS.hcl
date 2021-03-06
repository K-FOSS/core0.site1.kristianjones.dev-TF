job "ns" {
  datacenters = ["core0site1"]

  group "powerdns" {
    count = 2

    spread {
      attribute = "$${node.unique.id}"
      weight = 100
    }

    network {
      mode = "cni/nomadcore1"

      port "dns" {
        to = 53

        static = 53

        host_network = "ns"
      }

      port "api" {
        to = 8080
      }
    }

    service {
      name = "powerdns"
      port = "dns"

      task = "powerdns-server"
      address_mode = "alloc"

      tags = ["$${NOMAD_ALLOC_INDEX}", "dns"]
    }

    service {
      name = "powerdns"
      port = "api"

      task = "powerdns-server"
      address_mode = "alloc"

      tags = ["http.api"]
    }

    task "powerdns-db" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      driver = "docker"

      config {
        image = "postgres:alpine3.14"

        command = "/usr/local/bin/psql"

        args = ["--file=/local/dns.psql", "--host=${PowerDNS.Database.Hostname}", "--username=${PowerDNS.Database.Username}", "--port=${PowerDNS.Database.Port}", "${PowerDNS.Database.Database}"]

        logging {
          type = "loki"
          config {
            loki-url = "http://http.distributor.loki.service.kjdev:8080/loki/api/v1/push"

            loki-external-labels = "job=powerdns,service=ns"
          }
        }
      }

      env {
        PGPASSFILE = "/secrets/.pgpass"
      }

      template {
        data = <<EOH
${PowerDNS.PSQL}
EOH

        destination = "local/dns.psql"
      }

      template {
        data = <<EOH
${PowerDNS.Database.Hostname}:${PowerDNS.Database.Port}:${PowerDNS.Database.Database}:${PowerDNS.Database.Username}:${PowerDNS.Database.Password}
EOH

        perms = "600"

        destination = "secrets/.pgpass"
      }
    }

    task "powerdns-server" {
      driver = "docker"

      config {
        image = "powerdns/pdns-auth-master"

        ports = ["dns"]

        args = ["--config-dir=/local/"]
      }

      template {
        data = <<EOH
${PowerDNS.Config}
EOH

        destination = "local/pdns.conf"
      }
    }
  }
}