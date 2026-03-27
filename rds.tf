resource "aws_db_subnet_group" "rr_db_subnet_group" {
  name       = "rr-db-subnet-group"
  subnet_ids = [
    aws_subnet.database_subnets[0].id,
    aws_subnet.database_subnets[1].id,
    aws_subnet.database_subnets[2].id
  ]
}

resource "aws_db_instance" "ritual_roast_db" {
  identifier = "rr-db"
  name       = "ritual_roast" # AWS Provider 3.x syntax

  engine            = var.mysql_engine
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  multi_az          = true

  db_subnet_group_name   = aws_db_subnet_group.rr_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.Database-SG.id]

  # DYNAMIC CREDENTIALS: Pulls from the Secret "AWSCURRENT" version
  username = jsondecode(data.aws_secretsmanager_secret_version.latest_credentials.secret_string)["username"]
  password = jsondecode(data.aws_secretsmanager_secret_version.latest_credentials.secret_string)["password"]

  skip_final_snapshot = true

  # Start the DB only after the skeleton secret version exists
  depends_on = [aws_secretsmanager_secret_version.db_secret_version]

  lifecycle {
    # CRITICAL: Prevents Terraform from overwriting passwords
    # Tell Terraform: "Once created, let the Secret Rotation handle the password" 
    # changed by the Rotation Lambda.
    ignore_changes = [password]
  }

  tags = merge(local.common_tags, {
    Name = "rr-db"
  })
}