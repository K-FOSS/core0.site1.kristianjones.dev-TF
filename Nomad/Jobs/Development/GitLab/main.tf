terraform {
  required_providers {
    #
    # Hashicorp Vault
    #
    # Docs: https://registry.terraform.io/providers/hashicorp/vault/latest/docs
    #
    nomad = {
      source = "hashicorp/nomad"
      version = "1.4.15"
    }

    #
    # GitHub Provider
    #
    # Used to fetch the latest PSQL file
    #
    # Docs: https://registry.terraform.io/providers/integrations/github/latest
    #
    github = {
      source = "integrations/github"
      version = "4.17.0"
    }

    #
    # Hashicorp Terraform HTTP Provider
    #
    # Docs: https://registry.terraform.io/providers/hashicorp/http/latest/docs
    #
    http = {
      source = "hashicorp/http"
      version = "2.1.0"
    }

    #
    # Randomness
    #
    # TODO: Find a way to best improve true randomness?
    #
    # Docs: https://registry.terraform.io/providers/hashicorp/random/latest/docs
    #
    random = {
      source = "hashicorp/random"
      version = "3.1.0"
    }
  }
}

resource "random_id" "WorkHorseKey" {
  byte_length = 32
}

resource "random_id" "KASKey" {
  byte_length = 32
}

resource "random_password" "ShellPassword" {
  length = 128
  special = false
}

#
# Gitaly
#

resource "random_password" "PraefectPassword" {
  length = 128
  special = false
}

locals {
  GitLab = {
    Secrets = {
      WorkHorse = random_id.WorkHorseKey.b64_std

      Shell = random_password.ShellPassword.result

      KAS = random_id.KASKey.b64_std

      Praefect = random_password.PraefectPassword.result
    }
  }
}


#
# GitLab Database
#

resource "nomad_job" "GitLabDatabaseJob" {
  jobspec = templatefile("${path.module}/Jobs/GitLabDatabase.hcl", {
    Image = {
      Repo = "registry.kristianjones.dev/gitlab/gitlab-org/build/cng"

      Tag = "v14.5.0"
    }

    Secrets = local.GitLab.Secrets

    WebService = {
      TLS = var.TLS.WebService

      EntryScript = file("${path.module}/Configs/WebService/Entry.sh")

      Templates = {
        Cable = templatefile("${path.module}/Configs/WebService/Cable.yaml", {

        })

        Database = templatefile("${path.module}/Configs/WebService/Database.yaml", {
          Database = var.Database.Core
        })

        GitlabERB = templatefile("${path.module}/Configs/WebService/Gitlab.yaml.erb", {
          OpenID = var.OpenID

          SMTP = var.SMTP

          S3 = var.S3

          Praefect = {
            Token = local.GitLab.Secrets.Praefect
          }
        })

        Resque = templatefile("${path.module}/Configs/WebService/Resque.yaml", {
        })

        Secrets = templatefile("${path.module}/Configs/WebService/Secrets.yaml", {
        })

      }
    }
  })
}

#
# Gitlab Gitaly
#

# resource "nomad_job" "GitLabGitalyJob" {
#   jobspec = templatefile("${path.module}/Jobs/GitLabGitaly.hcl", {
#     Image = {
#       Repo = "registry.kristianjones.dev/gitlab/gitlab-org/build/cng"

#       Tag = "master"
#     }

#     Gitaly = {
#       GitConfig = templatefile("${path.module}/Configs/Gitaly/gitconfig", {
#       })

#       Config = templatefile("${path.module}/Configs/Gitaly/config.toml", {
#       })
#     }
#   })
# }

#
# GitLab Pages
# 

# resource "nomad_job" "GitLabPagesJob" {
#   jobspec = templatefile("${path.module}/Jobs/GitLabPages.hcl", {
#     Image = {
#       Repo = "registry.kristianjones.dev/gitlab/gitlab-org/build/cng"

#       Tag = "master"
#     }

#     Pages = {
#       Config = templatefile("${path.module}/Configs/Pages/Pages-config.erb", {
#       })
#     }
#   })
# }

#
# GitLab Shell
# 

resource "nomad_job" "GitLabShellJob" {
  jobspec = templatefile("${path.module}/Jobs/GitLabShell.hcl", {
    Image = {
      Repo = "registry.kristianjones.dev/gitlab/gitlab-org/build/cng"

      Tag = "master"
    }

    Secrets = local.GitLab.Secrets

    Shell = {
      Config = templatefile("${path.module}/Configs/Shell/Config.yml.erb", {
      })
    }
  })
}

#
# GitLab SideKiq
# 

resource "nomad_job" "GitLabSideKiqJob" {
  jobspec = templatefile("${path.module}/Jobs/GitLabSideKiq.hcl", {
    Image = {
      Repo = "registry.kristianjones.dev/gitlab/gitlab-org/build/cng"

      Tag = "v14.5.0"
    }

    Secrets = local.GitLab.Secrets

    Sidekiq = {
      Templates = {
        Cable = templatefile("${path.module}/Configs/WebService/Cable.yaml", {

        })

        Database = templatefile("${path.module}/Configs/Sidekiq/Database.yaml", {
          Database = var.Database.Core
        })

        GitlabYAML = templatefile("${path.module}/Configs/Sidekiq/Gitlab.yaml", {
          OpenID = var.OpenID

          SMTP = var.SMTP

          S3 = var.S3

          Praefect = {
            Token = local.GitLab.Secrets.Praefect
          }
        })

        Resque = templatefile("${path.module}/Configs/Sidekiq/Resque.yaml", {
        })

        SidekiqQueues = templatefile("${path.module}/Configs/Sidekiq/SidekiqQueues.yaml", {
        })
      }
    }
  })
}

#
# GitLab WebService
#

resource "nomad_job" "GitLabWebServcieJob" {
  jobspec = templatefile("${path.module}/Jobs/GitLabWebService.hcl", {
    Image = {
      Repo = "registry.kristianjones.dev/gitlab/gitlab-org/build/cng"

      Tag = "v14.5.0"
    }

    Secrets = local.GitLab.Secrets

    WebService = {
      TLS = var.TLS.WebService

      EntryScript = file("${path.module}/Configs/WebService/Entry.sh")

      Templates = {
        Cable = templatefile("${path.module}/Configs/WebService/Cable.yaml", {

        })

        Database = templatefile("${path.module}/Configs/WebService/Database.yaml", {
          Database = var.Database.Core
        })

        GitlabERB = templatefile("${path.module}/Configs/WebService/Gitlab.yaml.erb", {
          OpenID = var.OpenID

          SMTP = var.SMTP

          S3 = var.S3

          Praefect = {
            Token = local.GitLab.Secrets.Praefect
          }
        })

        Resque = templatefile("${path.module}/Configs/WebService/Resque.yaml", {
        })

        Secrets = templatefile("${path.module}/Configs/WebService/Secrets.yaml", {
        })

      }
    }
  })
}

#
# GitLab WorkHorse
#

resource "nomad_job" "GitLabWorkHorseJob" {
  jobspec = templatefile("${path.module}/Jobs/GitLabWorkHorse.hcl", {
    Image = {
      Repo = "registry.kristianjones.dev/gitlab/gitlab-org/build/cng"

      Tag = "v14.5.0"
    }

    Secrets = local.GitLab.Secrets

    WorkHorse = {
      TLS = var.TLS.WorkHorse

      Config = templatefile("${path.module}/Configs/WorkHorse/WorkhorseConfig.toml", {
        S3 = var.S3
      })
    }
  })
}

#
# GitLab Kubernetes Agent Server
#

resource "nomad_job" "GitLabKASJob" {
  jobspec = templatefile("${path.module}/Jobs/GitLabKAS.hcl", {
    Image = {
      Repo = "registry.kristianjones.dev/gitlab/gitlab-org/cluster-integration/gitlab-agent"

      Tag = "v14.5.0"
    }

    Secrets = local.GitLab.Secrets

    KAS = {
      Config = templatefile("${path.module}/Configs/KAS/Config.yaml", {

      })
    }
  })
}

#
# GitLab Praefect
#

resource "nomad_job" "GitLabPraefectJob" {
  jobspec = templatefile("${path.module}/Jobs/GitLabPraefect.hcl", {
    Image = {
      Repo = "registry.kristianjones.dev/gitlab/gitlab-org/build/cng"

      Tag = "v14.5.0"
    }

    Secrets = local.GitLab.Secrets

    Praefect = {
      Config = templatefile("${path.module}/Configs/Praefect/config.toml", {
        PraefectToken = local.GitLab.Secrets.Praefect

        Database = var.Database.Praefect
      })
    }
  })
}