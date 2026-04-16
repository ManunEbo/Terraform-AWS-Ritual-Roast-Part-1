
# The Lambda Function
resource "aws_lambda_function" "secret_rotation_function" {
  function_name = "SecretRotationFunction"
  handler       = "index.lambda_handler"
  runtime       = "python3.9"

  s3_bucket        = var.s3_bucket
  s3_key           = "index.zip"
  source_code_hash = filebase64sha256("./index.zip")

  role = aws_iam_role.lambda_secrets_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.database_subnets[0].id,
      aws_subnet.database_subnets[1].id,
      aws_subnet.database_subnets[2].id
    ]
    # security_group_ids = [aws_security_group.Database-SG.id]
    # Change to lambda security group
    security_group_ids = [aws_security_group.Lambda-SG.id]
  }

  # Ensure networking permissions exist before creating the Lambda
  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc_access
  ]

  timeout = 30

  tags = merge(local.common_tags, {
    Name = "SecretRotationFunction"
  })
}