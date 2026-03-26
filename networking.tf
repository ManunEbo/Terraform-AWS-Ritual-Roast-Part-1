#--------------------------------------------------------------
#-------------------------- VPC -------------------------------
#--------------------------------------------------------------

# Create the Ritual-Roast VPC
resource "aws_vpc" "RR-VPC" {
  cidr_block = var.vpc_cidr

  # Enable dns support to allow the database to share the ip address
  # i.e. to be able to resolve the dns names 
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = var.vpc_name
  })
}

#--------------------------------------------------------------
#--------------------- Creating Subnets -----------------------
#--------------------------------------------------------------

# Create the public subnets
resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_list)
  vpc_id            = aws_vpc.RR-VPC.id
  cidr_block        = var.public_subnet_list[count.index].cidr
  availability_zone = var.public_subnet_list[count.index].az

  # Enable public IP addressing
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = var.public_subnet_list[count.index].subnet_name
  })
}

# Creating Web tier subnets
resource "aws_subnet" "web_subnets" {
  count             = length(var.web_subnet_list)
  vpc_id            = aws_vpc.RR-VPC.id
  cidr_block        = var.web_subnet_list[count.index].cidr
  availability_zone = var.web_subnet_list[count.index].az

  tags = merge(local.common_tags, {
    Name = var.web_subnet_list[count.index].subnet_name
  })
}


# Creating App tier subnets. Note, these subnets are for future use 
resource "aws_subnet" "app_subnets" {
  count             = length(var.app_subnet_list)
  vpc_id            = aws_vpc.RR-VPC.id
  cidr_block        = var.app_subnet_list[count.index].cidr
  availability_zone = var.app_subnet_list[count.index].az

  tags = merge(local.common_tags, {
    Name = var.app_subnet_list[count.index].subnet_name
  })
}


# Creating the database subnets
resource "aws_subnet" "database_subnets" {
  count             = length(var.database_subnet_list)
  vpc_id            = aws_vpc.RR-VPC.id
  cidr_block        = var.database_subnet_list[count.index].cidr
  availability_zone = var.database_subnet_list[count.index].az

  tags = merge(local.common_tags, {
    Name = var.database_subnet_list[count.index].subnet_name
  })
}