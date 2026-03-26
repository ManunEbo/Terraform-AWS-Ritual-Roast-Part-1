# AWS Region
variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

# VPC Name
variable "vpc_name" {
  type    = string
  default = "ritual-roast-vpc"
}

# VPC cidr range
variable "vpc_cidr" {
  type    = string
  default = "10.16.0.0/16"
}

#------------------------------------------------------------------------------------
# ****** Use lists with objects to put subnet name, cidr range and AZ together ******
#------------------------------------------------------------------------------------



variable "public_subnet_list" {
  type = list(object({
    subnet_name = string
    cidr        = string
    az          = string
  }))
}


# Web tier subnets
variable "web_subnet_list" {
  type = list(object({
    subnet_name = string
    cidr        = string
    az          = string
  }))
}

# App subnets
variable "app_subnet_list" {
  type = list(object({
    subnet_name = string
    cidr        = string
    az          = string
  }))
}


# Database subnets
variable "database_subnet_list" {
  type = list(object({
    subnet_name = string
    cidr        = string
    az          = string
  }))
}


# Environment settings
variable "environment" {
  description = "Environment for deployment"
  type        = string
  default     = "dev"
}

#------------------------------------------------------------------------------------
#---------------------- Defining database credentials -------------------------------
#------------------------------------------------------------------------------------

# Defining the username of the database
variable "db_username" {
  description = "The username of the database"
  type        = string
  sensitive   = true
}

# Defining the password for the above database user
variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}


#------------------------------------------------------------------------------------
#---------------------------- S3 bucket variable ------------------------------------
#------------------------------------------------------------------------------------

variable "s3_bucket" {
  type = string
}