data "aws_region" "current" {}

# Create the Secret Container
resource "aws_secretsmanager_secret" "db_secret" {
  name                    = "rr-db-secret-14"
  recovery_window_in_days = 0 

  tags = merge(local.common_tags, {
    Name = "rr-db-secret-14"
  })
}

# STAGE 1: Skeleton Version (No Host)
resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = "placeholder"
    port     = 3306
    dbname   = "ritual_roast"
  })
}

# Data source for RDS to read STAGE 1
data "aws_secretsmanager_secret_version" "rr_db_credentials" {
  secret_id  = aws_secretsmanager_secret.db_secret.id
  depends_on = [aws_secretsmanager_secret_version.db_secret_version]
}

# STAGE 2: Full Version (With Host)
resource "aws_secretsmanager_secret_version" "db_host_update" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    dbname   = "ritual_roast"
    port     = 3306
    host     = aws_db_instance.ritual_roast_db.address
  })
}

# Rotation
resource "aws_secretsmanager_secret_rotation" "db_secret_rotation" {
  secret_id           = aws_secretsmanager_secret.db_secret.id
  rotation_lambda_arn = aws_lambda_function.secret_rotation_function.arn
  
  rotation_rules {
    automatically_after_days = 7
  }

  depends_on = [aws_secretsmanager_secret_version.db_host_update] 
}