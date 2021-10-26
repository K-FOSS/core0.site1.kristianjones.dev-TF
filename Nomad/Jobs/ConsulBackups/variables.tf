variable "Consul" {
  type = object({
    Hostname = string
    Port = number
  
    Token = string
  })
}


variable "S3" {
  type = object({
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
}