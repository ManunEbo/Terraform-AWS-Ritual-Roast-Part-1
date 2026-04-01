data "aws_region" "current" {}

# 1. The Secret Container
resource "aws_secretsmanager_secret" "db_secret" {
  name                    = "rr-db-secret-14"
  recovery_window_in_days = 0

  tags = merge(local.common_tags, {
    Name = "rr-db-secret-14"
  })
}

# 2. STAGE 1: Skeleton Version (Initial Credentials)
# This allows the RDS to boot without needing its own Host address yet.
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

# 3. THE DYNAMIC POINTER
# This always tracks the "AWSCURRENT" label. 
# It ensures that even after a rotation, RDS sees the LATEST secret.
data "aws_secretsmanager_secret_version" "latest_credentials" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  # Explicitly depends on the skeleton existing so it can read it on the first run
  depends_on = [aws_secretsmanager_secret_version.db_secret_version]
}

# 4. STAGE 2: Full Version (Adds the Real Host)
# Explicitly depends on the RDS being 'Available' to ensure the address is valid.
resource "aws_secretsmanager_secret_version" "db_host_update" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    dbname   = "ritual_roast"
    port     = 3306
    host     = aws_db_instance.ritual_roast_db.address
  })

  # CRITICAL: Ensures the DB is 100% ready before we fetch its address
  depends_on = [aws_db_instance.ritual_roast_db]

  # Critical Fix: Stops Terraform from resetting the password on subsequent tf apply!
  lifecycle {
    ignore_changes = [ secret_string ]
  }
}

# 5. Rotation Logic
resource "aws_secretsmanager_secret_rotation" "db_secret_rotation" {
  secret_id           = aws_secretsmanager_secret.db_secret.id
  rotation_lambda_arn = aws_lambda_function.secret_rotation_function.arn

  rotation_rules {
    automatically_after_days = 7
  }

  # Ensure the Full Secret exists before the Lambda tries to rotate anything
  depends_on = [aws_secretsmanager_secret_version.db_host_update]
}