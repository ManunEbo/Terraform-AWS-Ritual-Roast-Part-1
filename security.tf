#--------------------------------------------------------------
# 1. LoadBalancer-SG: The Front Door
#--------------------------------------------------------------
resource "aws_security_group" "LoadBalancer-SG" {
  name        = "LoadBalancer-SG"
  description = "Allow HTTP (port 80) from internet and outbound to instances"
  vpc_id      = aws_vpc.RR-VPC.id

  tags = merge(local.common_tags, {
    Name = "LoadBalancer-SG"
  })
}

# Ingress: Allow anyone on the internet to hit the ALB on port 80
resource "aws_security_group_rule" "alb_allow_80_inbound" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.LoadBalancer-SG.id
}

# Allow ALB to send traffic OUT to the Web-App instances on port 5000
resource "aws_security_group_rule" "alb_allow_outbound_to_web_app" {
  type                     = "egress"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.LoadBalancer-SG.id
  source_security_group_id = aws_security_group.Web-App-SG.id
}

#--------------------------------------------------------------
# 2. Web-App-SG: The Application Tier
#--------------------------------------------------------------
resource "aws_security_group" "Web-App-SG" {
  name        = "Web-App-SG"
  description = "Allow TCP 5000 from ALB and all outbound for updates/S3"
  vpc_id      = aws_vpc.RR-VPC.id

  tags = merge(local.common_tags, {
    Name = "Web-App-SG"
  })
}

# Ingress: Allow ALB to reach Flask on port 5000
resource "aws_security_group_rule" "allow_ingress_5000_from_LoadBalancer-SG" {
  type                     = "ingress"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.Web-App-SG.id
  source_security_group_id = aws_security_group.LoadBalancer-SG.id
}

# Egress: Allow instances to reach S3, download Pip, and talk to Database
resource "aws_security_group_rule" "web_app_allow_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # Allows all protocols
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Web-App-SG.id
}

#--------------------------------------------------------------
# 3. Database-SG: The Data Tier
#--------------------------------------------------------------
resource "aws_security_group" "Database-SG" {
  name        = "Database-SG"
  description = "Allow MySQL 3306 from Web-App-SG"
  vpc_id      = aws_vpc.RR-VPC.id

  tags = merge(local.common_tags, {
    Name = "Database-SG"
  })
}

# Ingress: Allow the Web-App instances to connect to MySQL
resource "aws_security_group_rule" "allow_3306_from_Web-APP" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.Database-SG.id
  source_security_group_id = aws_security_group.Web-App-SG.id
}

# Ingress: Allow Secrets Manager Lambda (self-reference) for rotation
resource "aws_security_group_rule" "allow_3306_from_Database-SG" {
  type                     = "ingress"
  description              = "Allow TCP 3306 from itself for rotation"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.Database-SG.id
  source_security_group_id = aws_security_group.Database-SG.id
}

# Egress: Standard all-traffic outbound (needed for DB responses)
# This allows the lambda function to talk to Secrets Manager and the database
# since the lambda function is attached to the same security group
# resource "aws_security_group_rule" "database_egress_all" {
#   type              = "egress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.Database-SG.id
# }

# Change to allow the database to accept traffic from Lambda-SG rather than itself
resource "aws_security_group_rule" "allow_3306_from_lambda" {
  type = "ingress"  
  description = "Allow TCP 3306 from Lambda for rotation"
  from_port = 3306
  to_port = 3306
  protocol = "tcp"
  security_group_id = aws_security_group.Database-SG.id
  source_security_group_id = aws_security_group.Lambda-SG.id
}

#--------------------------------------------------------------
# 4. Lambda security group - Lambda-SG
#--------------------------------------------------------------
resource "aws_security_group" "Lambda-SG" {
  name = "Lambda-SG"
  description = "Allow Lambda to reach DB and internet via NAT Gateway"
  vpc_id = aws_vpc.RR-VPC.id

  tags = merge(local.common_tags, {
    Name = "Lambda-SG"
  })  
}

# Egress: Lambda -> Database (port 3306)
resource "aws_security_group_rule" "lambda_egress_to_db" {
  type = "ingress" # Note: this will be used in Database-SG above
  from_port = 3306
  to_port = 3306
  protocol = "tcp"
  security_group_id = aws_security_group.Lambda-SG.id
  source_security_group_id =  aws_security_group.Database-SG.id  
}

# Egress: Lambda -> Public Internet / Secrets Manager API (Port 443)
resource "aws_security_group_rule" "lambda_egress_to_secrets_manager" {
  type = "egress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"] # Reaches Secrets Manager API through the NAT Gateway
  security_group_id = aws_security_group.Lambda-SG.id
}