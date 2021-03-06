#
# Database
#

variable "Database" {
  type = object({
    Core = object({
      Hostname = string
      Port = number

      Database = string

      Username = string
      Password = string
    })

    Praefect = object({
      Hostname = string
      Port = number

      Database = string

      Username = string
      Password = string
    })
  })
}

#
# LDAP
#

variable "LDAP" {
  type = object({
    Credentials = object({
      Username = string
      Password = string
    })
  })
}

#
# Secrets
#

variable "Secrets" {
  type = object({
    OpenIDSigningKey = string
  })
}

variable "TLS" {
  type = object({
    WebService = object({
      CA = string

      Cert = string
      Key = string
    })

    WorkHorse = object({
      CA = string

      Cert = string
      Key = string
    })

    Registry = object({
      CA = string
      
      Cert = string
      Key = string
    })
  })
}

#
# Object Storage for GitLab
#
variable "S3" {
  type = object({
    ArtifactsBucket = object({
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

    ExternalDiffsBucket = object({
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

    LFSBucket = object({
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

    UploadsBucket = object({
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

    PackagesBucket = object({
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

    DependencyProxyBucket = object({
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

    TerraformStateBucket = object({
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

    PagesBucket = object({
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

#
# OpenID
#
variable "OpenID" {
  type = object({
    ClientID = string

    ClientSecret = string
  })
}



#
# SMTP
# 

variable "SMTP" {
  type = object({
    Server = string
    Port = string

    Username = string
    Password = string
  })
}