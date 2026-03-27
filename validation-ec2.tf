# Below is a list of EC2 parameter validations

# Validating the instance type
variable "instance_type" {
  type = string
  validation {
    condition     = contains(["t2.micro", "t3.micro"], var.instance_type)
    error_message = "Instance type must be either 't2.micro' or 't3.micro'."
  }
}


# Ensure that the AMI used is the Amazon linux AMI
variable "ami" {
  type = string
  validation {
    condition     = var.ami == data.aws_ami.amazon_linux_2023.id
    error_message = "AMI must be Amazon Linux 23."
  }
}


# make volume size between 10 and 30 GB
variable "volume_size" {
  type = number
  validation {
    condition     = var.volume_size > 10 && var.volume_size < 40
    error_message = "Volume size must be greater than 10 and less than 30"
  }
}


# Limiting volume_type
variable "volume_type" {
  type = string
  validation {
    condition     = contains(["gp2", "gp3"], var.volume_type)
    error_message = "Volume type must be either 'gp2' or 'gp3'."
  }
}


# delete_on_termination
variable "delete_on_termination" {
  type = bool
  validation {
    condition     = var.delete_on_termination == true
    error_message = "Delete on termination must be set to 'true'."
  }
}

# Set the instance profile i.e. attach the role to access s3 and secret manager
variable "iam_instance_profile" {
  type = string
  validation {
    condition     = var.iam_instance_profile == aws_iam_role.rr_ec2_s3_secret_role.name
    error_message = "The iam_instance_profile must be set to the correct role name\n${aws_iam_role.rr_ec2_s3_secret_role.name}."
  }
}

# set the associate_public_ip_address to false as these instances should not be accessible publicly
variable "associate_public_ip_address" {
  type = bool
  validation {
    condition     = var.associate_public_ip_address == false
    error_message = "Please ensure that 'associate_public_ip_address' is disabled\nby setting it to false."
  }
}