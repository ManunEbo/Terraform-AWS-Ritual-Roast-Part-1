# Creating subnet group
resource "aws_db_subnet_group" "rr_db_subnet_group" {
  name       = "rr-db-subnet-group"
  subnet_ids = [
    aws_subnet.database_subnets[0].id,
    aws_subnet.database_subnets[1].id,
    aws_subnet.database_subnets[2].id
  ]

  tags = {
    Name = "rr-db-subnet-group"
  }
}

# Creating the database
resource "aws_db_instance" "ritual_roast_db" {
  identifier = "rr-db"

  # In AWS Provider 3.x, use 'name' to create the initial database
  name = "ritual_roast"

  engine            = var.mysql_engine
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  multi_az          = true

  db_subnet_group_name   = aws_db_subnet_group.rr_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.Database-SG.id]

  # Pulling credentials from the Data Source (Skeleton Secret)
  username = jsondecode(data.aws_secretsmanager_secret_version.rr_db_credentials.secret_string)["username"]
  password = jsondecode(data.aws_secretsmanager_secret_version.rr_db_credentials.secret_string)["password"]

  skip_final_snapshot = true

  # Ensure the Skeleton Secret version is physically created before RDS attempts to pull it
  depends_on = [aws_secretsmanager_secret_version.db_secret_version]

  tags = merge(local.common_tags, {
    Name = "rr-db"
  })
}