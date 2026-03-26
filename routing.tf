/* Altering the default route table for RR-VPC:
Edit main route table for ritual-roast-vpc
Note, this route table is created automatically with the VPC
All subnets both public and private are implicitly associated
with this route table
Thus it should not have a route to the internet as that would
expose all subnets to the internet.
Instead we must add a NAT Gateway here to enable outbound access
to the internet for all subnets.
*/

resource "aws_default_route_table" "RR-VPC" {
  default_route_table_id = aws_vpc.RR-VPC.default_route_table_id

  # Add a route via NAT gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.rr_nat_gateway.id
  }

  tags = merge(local.common_tags, {
    Name = "RR-Default-rt"
  })
}


# Creating ritual roast public route table (ritual-roast-public-rt)
/*
Create a public route table that we can associate with the
public subnets
Create a route to the internet via the Internet Gateway
0.0.0.0/0 via IGW
Associate the public subnets to this route table
Explicit Subnet associations
*/

resource "aws_route_table" "ritual-roast-public-rt" {
  vpc_id = aws_vpc.RR-VPC.id

  # Add the route via IGW
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ritual-roast-igw.id
  }

  tags = merge(local.common_tags, {
    Name = "ritual-roast-public-rt"
  })
}

# Lets associate all the public subnets to the public route table
resource "aws_route_table_association" "public_route_table_association" {
  depends_on = [aws_subnet.public_subnets]

  route_table_id = aws_route_table.ritual-roast-public-rt.id
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id

}
