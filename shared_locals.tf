locals {
  Project       = "ritual-roast-webapp"
  Project_owner = "Elvy ManunEbo"
  Terraform     = "true"
  Environment   = var.environment
  Region        = var.aws_region
  # Modified_time = formatdate("YYYY-MM-DD HH:mm:ss", timestamp())

  # create_before_destroy = var.create_before_destroy == "true"
}


# Composite locals 
locals {
  common_tags = {
    Project       = local.Project
    Project_owner = local.Project_owner
    Terraform     = local.Terraform
    Environment   = local.Environment
    Region        = local.Region
    # Modified_time = local.Modified_time
  }
}

