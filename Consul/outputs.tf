output "Patroni" {
  value = {
    Hostname = "core0.site1.kristianjones.dev"
    Port = 8500


    Prefix = local.Patroni.Prefix
    ServiceName = local.Patroni.ServiceName

    Token = data.consul_acl_token_secret_id.PatroniToken.secret_id
  }
}

#
# Grafana Cortex 
#
output "Cortex" {
  value = {
    Hostname = "core0.site1.kristianjones.dev"
    Port = 8500


    Prefix = local.Cortex.Prefix

    Token = data.consul_acl_token_secret_id.CortexToken.secret_id
  }
}


output "Pomerium" {
  value = {
    OIDVaultPath = data.consul_key_prefix.PomeriumOID.subkeys["vault_path"]
  }
}