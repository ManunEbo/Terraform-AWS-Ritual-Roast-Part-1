# Creating subnet group
resource "aws_db_subnet_group" "rr_db_subnet_group" {
  name = "rr-db-subnet-group"
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
# resource "aws_db_instance" "Ritual-roast-db" {
#   identifier             = "rr-db"
#   engine                 = var.mysql_engine
#   instance_class         = var.db_instance_class
#   allocated_storage      = var.db_allocated_storage
#   multi_az               = true
#   db_subnet_group_name   = aws_db_subnet_group.rr-db-subnet-group.name
#   vpc_security_group_ids = [aws_security_group.Databse-SG.id]
#   username               = jsondecode(data.aws_secretsmanager_secret_version.rr_db_credentials.secret_string)["username"]
#   password               = jsondecode(data.aws_secretsmanager_secret_version.rr_db_credentials.secret_string)["password"]
#   skip_final_snapshot    = true

#   tags = merge(local.common_tags, {
#     Name = "rr-db"
#   })
# }

# Creating the database
# Creating the database
# resource "aws_db_instance" "Ritual-roast-db" {
#   identifier = "rr-db"

#   # Use "name" for older provider versions, "db_name" for newer ones.
#   # If "db_name" failed, "name" is the one you need:
#   name = "ritual_roast"

#   engine                 = var.mysql_engine
#   instance_class         = var.db_instance_class
#   allocated_storage      = var.db_allocated_storage
#   multi_az               = true
#   db_subnet_group_name   = aws_db_subnet_group.rr-db-subnet-group.name
#   vpc_security_group_ids = [aws_security_group.Databse-SG.id]

#   username = jsondecode(data.aws_secretsmanager_secret_version.rr_db_credentials.secret_string)["username"]
#   password = jsondecode(data.aws_secretsmanager_secret_version.rr_db_credentials.secret_string)["password"]

#   skip_final_snapshot = true

#   tags = merge(local.common_tags, {
#     Name = "rr-db"
#   })
# }

# resource "aws_db_instance" "Ritual-roast-db" {
#   identifier = "rr-db"

#   # This creates the 'ritual_roast' database automatically on startup
#   name = "ritual_roast"

#   engine            = var.mysql_engine
#   instance_class    = var.db_instance_class
#   allocated_storage = var.db_allocated_storage
#   storage_type      = "gp3"
#   multi_az          = true

#   # Networking
#   db_subnet_group_name   = aws_db_subnet_group.rr-db-subnet-group.name
#   vpc_security_group_ids = [aws_security_group.Databse-SG.id]

#   # Credentials retrieved from Secrets Manager via the data source above
#   username = jsondecode(data.aws_secretsmanager_secret_version.rr_db_credentials.secret_string)["username"]
#   password = jsondecode(data.aws_secretsmanager_secret_version.rr_db_credentials.secret_string)["password"]

#   skip_final_snapshot = true

#   # Ensure the secret version is ready before trying to create the DB
#   depends_on = [aws_secretsmanager_secret_version.db_secret_version]

#   tags = merge(local.common_tags, {
#     Name = "rr-db"
#   })
# }

# resource "aws_db_instance" "Ritual-roast-db" {
#   identifier        = "rr-db"

#   # 'name' creates the 'ritual_roast' database automatically
#   name              = "ritual_roast" 

#   engine            = var.mysql_engine
#   instance_class    = var.db_instance_class
#   allocated_storage = var.db_allocated_storage
#   storage_type      = "gp3"
#   multi_az          = true

#   db_subnet_group_name   = aws_db_subnet_group.rr-db-subnet-group.name
#   vpc_security_group_ids = [aws_security_group.Database-SG.id]

#   # Pulling credentials from the Secret created above
#   username = jsondecode(data.aws_secretsmanager_secret_version.rr_db_credentials.secret_string)["username"]
#   password = jsondecode(data.aws_secretsmanager_secret_version.rr_db_credentials.secret_string)["password"]

#   skip_final_snapshot = true

#   # This ensures the secret exists so the RDS can pull the username/password
#   depends_on = [aws_secretsmanager_secret_version.db_secret_version]

#   tags = merge(local.common_tags, {
#     Name = "rr-db"
#   })
# }

resource "aws_db_instance" "ritual_roast_db" {
  identifier = "rr-db"

  # 'name' creates the 'ritual_roast' database automatically
  name = "ritual_roast"

  engine            = var.mysql_engine
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  multi_az          = true

  db_subnet_group_name   = aws_db_subnet_group.rr_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.Database-SG.id]

  # Pulling credentials from the Secret created above
  username = jsondecode(data.aws_secretsmanager_secret_version.rr_db_credentials.secret_string)["username"]
  password = jsondecode(data.aws_secretsmanager_secret_version.rr_db_credentials.secret_string)["password"]

  skip_final_snapshot = true

  # This ensures the secret exists so the RDS can pull the username/password
  depends_on = [aws_secretsmanager_secret_version.db_secret_version]

  tags = merge(local.common_tags, {
    Name = "rr-db"
  })
}