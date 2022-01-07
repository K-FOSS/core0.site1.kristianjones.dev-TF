job "network-monitoring-opennms-coreserver" {
  datacenters = ["core0site1"]

  group "opennms-core-server" {
    count = 2

    spread {
      attribute = "$${node.unique.id}"
      weight = 100
    }

    network {
      mode = "cni/nomadcore1"

      port "http" {
        to = 8980
      }
    }

    service {
      name = "opennms"
      port = "http"

      task = "opennms-core-server"
      address_mode = "alloc"

      tags = ["http.horizion"]
    }

    task "opennms-core-server" {
      driver = "docker"

      config {
        image = "${OpenNMS.Image.Repo}/horizon:${OpenNMS.Image.Tag}"

        args = ["-s"]

        memory_hard_limit = 2048

        mount {
          type = "tmpfs"
          target = "/opt/opennms-overlay/etc"
          readonly = false
          tmpfs_options = {
            size = 124000000
          }
        }

        mount {
          type = "bind"
          target = "/opt/opennms-overlay/confd/horizon-config.yaml"
          source = "local/HorizionConfig.yaml"
          readonly = false
        }

        mount {
          type = "bind"
          target = "/opt/opennms-overlay/etc/org.opennms.plugins.tss.cortex.cfg"
          source = "local/CortexConfig.cfg"
          readonly = false
        }

        mount {
          type = "bind"
          target = "/opt/opennms-overlay/etc/opennms.properties.d/cortex.properties"
          source = "local/cortex.properties"
          readonly = false
        }

        mount {
          type = "bind"
          target = "/opt/opennms-overlay/etc/featuresBoot.d/plugin-cortex-tss.boot"
          source = "local/featuresBoot.d/plugin-cortex-tss.boot"
          readonly = false
        }

        mount {
          type = "bind"
          target = "/etc/confd/confd.toml"
          source = "local/HorizionConfig.toml"
          readonly = false
        }

        sysctl = {
          "net.ipv4.ping_group_range" = "0 429496729"
        }
      }

      env {
        TZ = "America/Winnipeg"
      }

      template {
        data = <<EOF
${OpenNMS.Configs.HorizionConfig}
EOF

        destination = "local/HorizionConfig.yaml"

        perms = "777"
      }

      template {
        data = <<EOF
confdir = "/etc/confd"
backend = "file"
file = [ "/opt/opennms-overlay/confd/horizon-config.yaml" ]
log-level = "info"
EOF

        destination = "local/HorizionConfig.toml"

        perms = "777"
      }

      template {
        data = <<EOF
${OpenNMS.Configs.CortexConfig}
EOF

        destination = "local/CortexConfig.cfg"

        perms = "777"
      }

      template {
        data = <<EOF
org.opennms.timeseries.tin.metatags.tag.node=$${node:label}
org.opennms.timeseries.tin.metatags.tag.location=$${node:location}
org.opennms.timeseries.tin.metatags.tag.ifDescr=$${interface:if-description}
org.opennms.timeseries.tin.metatags.tag.label=$${resource:label}
EOF

        destination = "local/cortex.properties"

        perms = "777"
      }

      template {
        data = <<EOF
opennms-plugins-cortex-tss
EOF

        destination = "local/featuresBoot.d/plugin-cortex-tss.boot"

        perms = "777"
      }

      artifact {
        source = "https://raw.githubusercontent.com/opennms-forge/stack-play/master/minimal-horizon-cortex/container-fs/horizon/opt/opennms/deploy/opennms-cortex-tss-plugin.kar"
        destination = "local/Artifacts/opennms-cortex-tss-plugin.kar"
      }


      resources {
        cpu = 512

        memory = 1024
        memory_max = 2048
      }
    }
  }
}