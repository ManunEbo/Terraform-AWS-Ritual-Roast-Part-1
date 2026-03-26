#--------------------------------------------------------------
#----------------- Creating Internet Gateway ------------------
#--------------------------------------------------------------

resource "aws_internet_gateway" "ritual-roast-igw" {
  vpc_id = aws_vpc.RR-VPC.id

  tags = merge(local.common_tags, {
    Name = "ritual-roast-igw"
  })
}

#--------------------------------------------------------------
#------------------- Creating NAT Gateway ---------------------
#--------------------------------------------------------------

# First requesting an Elastic IP (EIP) for the NAT gateway
resource "aws_eip" "nat_gateway_eip" {
  depends_on = [aws_internet_gateway.ritual-roast-igw]

  tags = merge(local.common_tags, {
    Name = "nat_gateway_eip"
  })
}

# creating the NAT Gateway
resource "aws_nat_gateway" "rr_nat_gateway" {
  depends_on = [aws_subnet.public_subnets]

  # Assign the EIP and the public subnet
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnets[1].id

  tags = merge(local.common_tags, {
    Name = "rr_nat_gateway"
  })
}