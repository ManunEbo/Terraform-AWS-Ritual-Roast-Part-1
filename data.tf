# Retrieve the s3 bucket
data "aws_s3_bucket" "RR-bucket" {
  bucket = var.s3_bucket
}


# Delay the execution of the next section
resource "time_sleep" "wait" {
  depends_on      = [aws_secretsmanager_secret_rotation.db_secret_rotation]
  create_duration = "5m" # Adjust the duration as needed.
}


#------------------------------------------------------------
#-------------------- Retrieve AMIs -------------------------
#------------------------------------------------------------

# Lets retrieve the amazon linux 23 ami id
data "aws_ami" "amazon_linux_2023" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*kernel-6.1-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_security_group" "Web-App-SG" {
  vpc_id = aws_vpc.RR-VPC.id
  filter {
    name   = "group-name"
    values = [aws_security_group.Web-App-SG.name]
  }
}