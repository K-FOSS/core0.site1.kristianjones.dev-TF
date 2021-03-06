job "tinkerbell-boots" {
  datacenters = ["core0site1"]

  group "boots" {
    count = 1

    restart {
      attempts = 3
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    network {
      mode = "cni/nomadcore1"

      port "http" {
        to = 80
      }

      port "syslog" {
        to = 514
      }

      port "dhcp" {
        to = 67
      }

      port "tftp" {
        to = 69
      }
    }

    task "wait-for-tink" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      driver = "exec"
      config {
        command = "sh"
        args = ["-c", "while ! nc -z tink-http-cont.service.dc1.kjdev 42114; do sleep 1; done"]
      }

      resources {
        cpu = 16
        memory = 16
        memory_max = 16
      }
    }

    service {
      name = "boots"
      port = "dhcp"

      task = "boots-server"
      address_mode = "alloc"

      tags = ["dhcp"]
    }

    service {
      name = "boots"
      port = "tftp"

      task = "boots-server"
      address_mode = "alloc"

      tags = ["tftp"]
    }


    task "boots-server" {
      driver = "docker"

      config {
        image = "quay.io/tinkerbell/boots:${Version}"

        command = "/usr/bin/boots"

        args = ["-dhcp-addr", "0.0.0.0:67", "-http-addr", "0.0.0.0:80", "-tftp-addr", "0.0.0.0:69", "-log-level", "DEBUG"]

        logging {
          type = "loki"
          config {
            loki-url = "http://http.distributor.loki.service.kjdev:8080/loki/api/v1/push"

            loki-external-labels = "job=tinkerbell,service=boots"
          }
        }
      }

      env {
        #
        # Addresses/Networking
        #
        BOOTP_BIND = "0.0.0.0:67"
        HTTP_BIND = "0.0.0.0:80"
        SYSLOG_BIND = "0.0.0.0:514"
        TFTP_BIND = "0.0.0.0:69"

        #
        # DNS
        #
        DNS_SERVERS = "10.1.1.53"

        #
        # Misc
        #
        DATA_MODEL_VERSION = "1"
        API_CONSUMER_TOKEN = "ignored"
        API_AUTH_TOKEN = "ignored"

        FACILITY = "onprem"
        FACILITY_CODE = "onprem"

        #
        # Packet
        #
        PACKET_ENV = "testing"
        PACKET_VERSION = "ignored"

        ROLLBAR_TOKEN = "ignored"
        ROLLBAR_DISABLE = "1"
        


        #
        # Container Registry Mirror
        #
        DOCKER_REGISTRY = "registry.kristianjones.dev:443"
        REGISTRY_USERNAME = "${Boots.Registry.Username}"
        REGISTRY_PASSWORD = "${Boots.Registry.Password}"


        PUBLIC_FQDN = "boots.service.dc1.kjdev"

        #
        # Mirror
        #
        MIRROR_HOST = "http-cont.service.kjdev:8080"
        #PUBLIC_IP = "172.16.0.151"

        #
        # Tinkerbell
        #  
        TINKERBELL_GRPC_AUTHORITY = "tink-grpc-cont.service.dc1.kjdev:42113"
        TINKERBELL_CERT_URL = "http://tink-http-cont.service.dc1.kjdev:42114/cert"
      }

      resources {
        cpu = 256
        memory = 256
        memory_max = 256
      }
    }
  }
}