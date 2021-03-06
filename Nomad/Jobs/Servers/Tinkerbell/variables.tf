variable "Database" {
  type = object({
    Hostname = string
    Port = number

    Database = string

    Username = string
    Password = string
  })
}

variable "TLS" {
  type = object({
    CA = string

    Tink = object({
      Cert = string
      Key = string
    })

    Hegel = object({
      Cert = string
      Key = string
    })

    Registry = object({
      Cert = string
      Key = string
    })
  })
}

variable "Boots" {
  type = object({
    Registry = object({
      Username = string
      Password = string
    })
  })
}

# variable "Terraform" {
#   type = object({
#     Vault = object({
#       Address = string

#       Token = string
#     })

#     Consul = object({
#       Address = string

#       Token = string
      
#     })
#   })
# }