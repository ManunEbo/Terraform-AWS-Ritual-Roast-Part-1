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

resource "aws_security_group_rule" "alb_allow_80_inbound" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.LoadBalancer-SG.id
}

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

resource "aws_security_group_rule" "allow_ingress_5000_from_LoadBalancer-SG" {
  type                     = "ingress"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.Web-App-SG.id
  source_security_group_id = aws_security_group.LoadBalancer-SG.id
}

resource "aws_security_group_rule" "web_app_allow_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Web-App-SG.id
}

#--------------------------------------------------------------
# 3. Database-SG: The Data Tier
#--------------------------------------------------------------
resource "aws_security_group" "Database-SG" {
  # Replace name = "Database-SG" with name_prefix
  name_prefix = "database-sg-" 
  
  description = "Allow MySQL 3306 from Web-App-SG and Lambda"
  vpc_id      = aws_vpc.RR-VPC.id

  lifecycle {
    create_before_destroy = true
  }

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

# Ingress: Allow Secrets Manager Lambda for rotation
resource "aws_security_group_rule" "allow_3306_from_lambda" {
  type                     = "ingress"  
  description              = "Allow TCP 3306 from Lambda for rotation"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.Database-SG.id
  source_security_group_id = aws_security_group.Lambda-SG.id
}

# NOTE: No egress rules are required for Database-SG because Security Groups 
# are stateful; responses to authorized ingress are allowed automatically.

#--------------------------------------------------------------
# 4. Lambda-SG: The Rotation Tier
#--------------------------------------------------------------
resource "aws_security_group" "Lambda-SG" {
  name        = "Lambda-SG"
  description = "Allow Lambda to reach DB and internet via NAT Gateway"
  vpc_id      = aws_vpc.RR-VPC.id

  tags = merge(local.common_tags, {
    Name = "Lambda-SG"
  })  
}

# Egress: Lambda -> Database (CRITICAL FIX: Changed type to egress)
resource "aws_security_group_rule" "lambda_egress_to_db" {
  type                     = "egress" 
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.Lambda-SG.id
  source_security_group_id = aws_security_group.Database-SG.id  
}

# Egress: Lambda -> Secrets Manager API (HTTPS) via NAT Gateway
resource "aws_security_group_rule" "lambda_egress_to_secrets_manager" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] 
  security_group_id = aws_security_group.Lambda-SG.id
}

# NOTE: No ingress rules are required for Lambda-SG as it only initiates outbound calls.