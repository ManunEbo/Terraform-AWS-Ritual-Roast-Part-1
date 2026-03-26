# Retrive the current region
data "aws_region" "current" {}


# Creating the Secrets Manager Secret
resource "aws_secretsmanager_secret" "db_secret" {
  # Naming the secret
  name = "rr-db-secret-14"

  # This tells AWS to bypass the 7-30 day "wait" period
  recovery_window_in_days = 0

  tags = merge(local.common_tags, {
    Name = "rr-db-secret-14"
  })
}

# resource "aws_secretsmanager_secret_version" "db_secret_version" {
#   secret_id = aws_secretsmanager_secret.db_secret.id
#   secret_string = jsonencode({
#     username = var.db_username
#     password = var.db_password
#   })

#   # Adding dependency to ensure the correct ordering
#   depends_on = [aws_secretsmanager_secret.db_secret]
# }

# resource "aws_secretsmanager_secret_version" "db_secret_version" {
#   secret_id = aws_secretsmanager_secret.db_secret.id

#   # We must include EVERY key the Python script expects:
#   secret_string = jsonencode({
#     username = var.db_username
#     password = var.db_password
#     host     = aws_db_instance.Ritual-roast-db.address # The RDS Endpoint
#     dbname   = aws_db_instance.Ritual-roast-db.name    # The database name (ritual_roast)
#     port     = 3306                                    # Standard MySQL port
#   })

#   # Ensure the DB exists first so we can grab its address
#   depends_on = [aws_db_instance.Ritual-roast-db]
# }


# resource "aws_secretsmanager_secret_version" "db_secret_version" {
#   secret_id = aws_secretsmanager_secret.db_secret.id

#   secret_string = jsonencode({
#     username = var.db_username
#     password = var.db_password
#     # Use string interpolation to build the address 
#     # This uses the identifier you've already defined (e.g., "rr-db")
#     host     = "${aws_db_instance.Ritual-roast-db.identifier}.${data.aws_region.current.name}.rds.amazonaws.com"
#     dbname   = "ritual_roast"
#     port     = 3306
#   })

#   # depends_on = [aws_db_instance.Ritual-roast-db]
# }

# resource "aws_secretsmanager_secret_version" "db_secret_version" {
#   secret_id = aws_secretsmanager_secret.db_secret.id

#   # All 5 keys your python script expects are here.
#   # "host" is a placeholder for the first run. 
#   # After the first 'apply', update this with the real RDS endpoint.
#   secret_string = jsonencode({
#     username = var.db_username
#     password = var.db_password
#     dbname   = "ritual_roast"
#     port     = 3306
#     host     = "rr-db.${data.aws_region.current.name}.rds.amazonaws.com"
#   })
# }


resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = "placeholder"  # Keep the KEY present so the structure never changes
    port     = 3306
    dbname   = "ritual_roast"
  })
}

# Data source to allow the RDS to read the secret we just created
# This must be based on the secret_version above, without the host
# This is done to avoid the chicken and egg loop cycle that the rds needs the secret
# and the secret needs the rds instance to exist first
# So above the host is removed
data "aws_secretsmanager_secret_version" "rr_db_credentials" {
  secret_id  = aws_secretsmanager_secret.db_secret.id
  depends_on = [aws_secretsmanager_secret_version.db_secret_version]
}

# Now adding the host
resource "aws_secretsmanager_secret_version" "db_host_update" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    dbname   = "ritual_roast"
    port     = 3306
    host     = aws_db_instance.ritual_roast_db.address # The "Magic" link
  })
}

# rotate the secret
# resource "aws_secretsmanager_secret_rotation" "db_secret_rotation" {
#   secret_id = aws_secretsmanager_secret.db_secret.id

#   rotation_lambda_arn = aws_lambda_function.secret_rotation_function.arn
#   # Adding rotation rule
#   rotation_rules {
#     # Specify the rotation frequency in days
#     automatically_after_days = 7
#   }

#   # Add dependency to ensure resoureces are created in the correct order
#   depends_on = [aws_secretsmanager_secret_version.db_secret_version] # Must be changed to the secret version with host updated
# }

# # resource "aws_secretsmanager_secret_rotation" "db_secret_rotation" {
# #   secret_id           = aws_secretsmanager_secret.db_secret.id
# #   rotation_lambda_arn = aws_lambda_function.rr_rotation_lambda.arn  # This resource does not exist
# #   rotation_rules {
# #     automatically_after_days = 30
# #   }
# #   depends_on = [aws_secretsmanager_secret_version.db_secret_version]
# # }

resource "aws_secretsmanager_secret_rotation" "db_secret_rotation" {
  secret_id = aws_secretsmanager_secret.db_secret.id

  rotation_lambda_arn = aws_lambda_function.secret_rotation_function.arn
  # Adding rotation rule
  rotation_rules {
    # Specify the rotation frequency in days
    automatically_after_days = 7
  }

  # Add dependency to ensure resoureces are created in the correct order
  depends_on = [aws_secretsmanager_secret_version.db_host_update] # Must be changed to the secret version with host updated
}
