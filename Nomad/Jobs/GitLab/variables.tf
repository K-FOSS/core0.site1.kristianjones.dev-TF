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
    WebService = {
      CA = string

      Cert = string
      Key = string
    }
  })
}

#
# Object Storage for GitLab
#
variable "S3" {
  type = object({
    RepoBucket = object({
      Connection = object({
        Hostname = string
        Port = number

        Endpoint = string
      })

      Credentials = object({
        AccessKey = string
        SecretKey = string
      })


      Bucket = string
    })
  }) 
}