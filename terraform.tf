# terraform {
#   required_version = "~> 1.7"

#   # Remote Backend: This saves the state file to S3 instead of the local disk
#   backend "s3" {
#     bucket       = "rr-capstone-5b160b287a99a6d9"
#     key          = "state/terraform.tfstate"
#     region       = "eu-west-2"
#     encrypt      = true
#     use_lockfile = true
#   }

#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 3.0"
#     }

#     random = {
#       source  = "hashicorp/random"
#       version = "3.1.0"
#     }
#   }
# }

# provider "aws" {
#   region = "eu-west-2"
# }


#-------------------------------------------
terraform {
  required_version = "1.14.3"

  # Remote Backend: This saves the state file to S3 instead of the local disk
  backend "s3" {
    bucket       = "rr-capstone-5b160b287a99a6d9"
    key          = "state/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.38.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}