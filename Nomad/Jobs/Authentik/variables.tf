#
# PostgreSQL Database Configuration
# 

variable "Database" {
  type = object({
    Hostname = string
    Port = number

    Database = string

    Username = string
    Password = string
  })
}

variable "Secrets" {
  type = object({
    SecretKey = string
  })
}