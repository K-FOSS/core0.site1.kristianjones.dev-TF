job "openproject-worker" {
  datacenters = ["core0site1"]

  group "seeder" {
    count = 1

    network {
      mode = "cni/nomadcore1"
    }

    task "openproject-db-seeder" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      driver = "docker"

      config {
        image = "registry.kristianjones.dev/cache/openproject/community:${Version}"

        args = ["./docker/prod/seeder"]

        memory_hard_limit = 128

        logging {
          type = "loki"
          config {
            loki-url = "http://http.ingress-webproxy.service.dc1.kjdev:8080/loki/api/v1/push"

            loki-external-labels = "job=openproject,service=dbseed"
          }
        }
      }

      resources {
        cpu = 64
        memory = 128
      }

      env {
        #
        # Cache
        #
        RAILS_CACHE_STORE = "memcache"
        OPENPROJECT_CACHE__MEMCACHE__SERVER = "memcache.openproject.service.dc1.kjdev:11211"

        #
        # Storage
        #
        # Docs: https://www.openproject.org/docs/installation-and-operations/installation/docker/
        #
        OPENPROJECT_ATTACHMENTS__STORAGE = "fog"
        OPENPROJECT_FOG_CREDENTIALS_ENDPOINT = "http://${S3.Connection.Endpoint}"
        
        OPENPROJECT_FOG_DIRECTORY = "${S3.Bucket}"
        OPENPROJECT_FOG_CREDENTIALS_PROVIDER = "aws"
        OPENPROJECT_FOG_CREDENTIALS_PATH__STYLE = "true"

        #
        # Multi Threading
        # 
        RAILS_MIN_THREADS = "4"
        RAILS_MAX_THREADS = "16"

        #
        # Scaling
        # 
        USE_PUMA = "true"

        #
        # Email
        #
        # TODO: Get Mail server online
        #
        IMAP_ENABLED = "false"


        #
        # Outbound Email
        #
        EMAIL_DELIVERY_METHOD = "smtp"
        SMTP_ADDRESS = "${SMTP.Server}"
        SMTP_PORT = "${SMTP.Port}"

        SMTP_DOMAIN = "kristianjones.dev"
        SMTP_AUTHENTICATION = "login"
        SMTP_ENABLE_STARTTLS_AUTO = "true"
      }


      template {
        data = <<EOH
#
# Database
#
DATABASE_URL="postgres://${Database.Username}:${Database.Password}@${Database.Hostname}:${Database.Port}/${Database.Database}?pool=20&encoding=unicode&reconnect=true"

#
# Storage
#
OPENPROJECT_FOG_CREDENTIALS_AWS__ACCESS__KEY__ID="${S3.Credentials.AccessKey}"
OPENPROJECT_FOG_CREDENTIALS_AWS__SECRET__ACCESS__KEY="${S3.Credentials.SecretKey}"

#
# Email
#

SMTP_USER_NAME="${SMTP.Username}"
SMTP_PASSWORD="${SMTP.Password}"
EOH

        destination = "secrets/file.env"
        env = true
      }
    }
  }

  group "workers" {
    count = 2

    network {
      mode = "cni/nomadcore1"
    }

    task "wait-for-cache" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      driver = "exec"
      config {
        command = "sh"
        args = ["-c", "while ! nc -z memcache.openproject.service.dc1.kjdev 11211; do sleep 1; done"]
      }

      resources {
        cpu = 16
        memory = 16
      }
    }

    task "openproject-worker" {
      driver = "docker"

      config {
        image = "registry.kristianjones.dev/cache/openproject/community:${Version}"

        args = ["./docker/prod/worker"]

        memory_hard_limit = 512

        logging {
          type = "loki"
          config {
            loki-url = "http://http.ingress-webproxy.service.dc1.kjdev:8080/loki/api/v1/push"

            loki-external-labels = "job=openproject,service=worker"
          }
        }
      }

      env {
        #
        # Cache
        #
        RAILS_CACHE_STORE = "memcache"
        OPENPROJECT_CACHE__MEMCACHE__SERVER = "memcache.openproject.service.dc1.kjdev:11211"

        #
        # Storage
        #
        # Docs: https://www.openproject.org/docs/installation-and-operations/installation/docker/
        #
        OPENPROJECT_ATTACHMENTS__STORAGE = "fog"
        OPENPROJECT_FOG_CREDENTIALS_ENDPOINT = "http://${S3.Connection.Endpoint}"
        
        OPENPROJECT_FOG_DIRECTORY = "${S3.Bucket}"
        OPENPROJECT_FOG_CREDENTIALS_PROVIDER = "aws"
        OPENPROJECT_FOG_CREDENTIALS_PATH__STYLE = "true"

        #
        # Multi Threading
        # 
        RAILS_MIN_THREADS = "4"
        RAILS_MAX_THREADS = "16"

        #
        # Scaling
        # 
        USE_PUMA = "true"

        #
        # Email
        #
        # TODO: Get Mail server online
        #
        IMAP_ENABLED = "false"


        #
        # Outbound Email
        #
        EMAIL_DELIVERY_METHOD = "smtp"
        SMTP_ADDRESS = "${SMTP.Server}"
        SMTP_PORT = "${SMTP.Port}"

        SMTP_DOMAIN = "kristianjones.dev"
        SMTP_AUTHENTICATION = "login"
        SMTP_ENABLE_STARTTLS_AUTO = "true"
      }

      resources {
        cpu = 128

        memory = 256
        memory_max = 512
      }


      template {
        data = <<EOH
#
# Database
#
DATABASE_URL="postgres://${Database.Username}:${Database.Password}@${Database.Hostname}:${Database.Port}/${Database.Database}?pool=20&encoding=unicode&reconnect=true"

#
# Storage
#
OPENPROJECT_FOG_CREDENTIALS_AWS__ACCESS__KEY__ID="${S3.Credentials.AccessKey}"
OPENPROJECT_FOG_CREDENTIALS_AWS__SECRET__ACCESS__KEY="${S3.Credentials.SecretKey}"

#
# Email
#

SMTP_USER_NAME="${SMTP.Username}"
SMTP_PASSWORD="${SMTP.Password}"
EOH

        destination = "secrets/file.env"
        env = true
      }
    }
  }
}