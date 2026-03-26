#------------------------------------------------------------
#----------- Creating a role for lambda function ------------
#------------------------------------------------------------

# 1. The Core IAM Role
resource "aws_iam_role" "lambda_secrets_role" {
  name = "lambda_secrets_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Effect = "Allow"
      Sid    = ""
    }]
  })

  tags = merge(local.common_tags, {
    Name = "lambda_secrets_role"
  })
}

# 2. Managed Policy for VPC Access (CRITICAL for the vpc_config)
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_secrets_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# 3. Managed Policy for Basic Execution (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_secrets_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


# 4. Custom Policy for Secrets Manager, S3, and Metrics
resource "aws_iam_policy" "rr_lambda_secrets_custom_policy" {
  name = "rr_lambda_secrets_manager_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:UpdateSecret",
          "secretsmanager:PutSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:eu-west-2:805530281081:secret:rr-db-secret-*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          data.aws_s3_bucket.RR-bucket.arn,
          "${data.aws_s3_bucket.RR-bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

# 5. Attach the Custom Policy above
resource "aws_iam_role_policy_attachment" "rr_custom_policy_attach" {
  role       = aws_iam_role.lambda_secrets_role.name
  policy_arn = aws_iam_policy.rr_lambda_secrets_custom_policy.arn
}


# 6. CRITICAL: Lambda Resource-Based Policy
# This solves the "AccessDeniedException: Secrets Manager cannot invoke..." error.
resource "aws_lambda_permission" "rr_allow_secretsmanager_to_call_lambda" {
  statement_id  = "AllowExecutionFromSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secret_rotation_function.function_name
  principal     = "secretsmanager.amazonaws.com"
}

#------------------------------------------------------------
#--- Creating an ec2 IAM role for s3 and Secrets Manager ----
#------------------------------------------------------------

resource "aws_iam_role" "rr_ec2_s3_secret_role" {
  name = "rr_ec2_s3_secret_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Effect = "Allow"
      Sid    = ""
    }]
  })

  tags = merge(local.common_tags, {
    Name = "rr_ec2_s3_secret_role"
  })
}


# Creating the role policy
# resource "aws_iam_policy" "rr_ec2_s3_secret_policy" {
#   name        = "rr_ec2_s3_secret_policy"
#   description = "Policy for EC2 to access specific s3 and Secrets Manager"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       # Adding the policy to access a specific S3 bucket and its contents.
#       {
#         Effect = "Allow"
#         Action = [
#           "s3:GetObject",
#           "s3:ListBucket"
#         ]
#         Resource = [
#           "${data.aws_s3_bucket.RR-bucket.arn}",
#           "${data.aws_s3_bucket.RR-bucket.arn}/*"
#         ]
#       },
#       # Adding the policy to get only secret values from Secret Manager
#       {
#         Effect = "Allow"
#         Action = [
#           "secretsmanager:GetSecretValue"
#         ]
#         Resource = "${data.aws_secretsmanager_secret_version.rr_db_credentials.arn}"
#       }
#     ]
#   })

#   tags = merge(local.common_tags, {
#     Name = "rr_ec2_s3_secret_policy"
#   })
# }


# Creating the role policy
resource "aws_iam_policy" "rr_ec2_s3_secret_policy" {
  name        = "rr_ec2_s3_secret_policy"
  description = "Policy for EC2 to access specific s3 and Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${data.aws_s3_bucket.RR-bucket.arn}",
          "${data.aws_s3_bucket.RR-bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        # Point to the SECRET ARN, not the SECRET_VERSION ARN
        # Resource = "${data.aws_secretsmanager_secret.rr_db_credentials.arn}"
        Resource = "${aws_secretsmanager_secret.db_secret.arn}"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "rr_ec2_s3_secret_policy"
  })
}


# Lets attach the policy to the role
resource "aws_iam_role_policy_attachment" "rr_ec2_s3_attach_policy" {
  role       = aws_iam_role.rr_ec2_s3_secret_role.name
  policy_arn = aws_iam_policy.rr_ec2_s3_secret_policy.arn
}

# Attach the AmazonSSMManagedInstanceCore Policy
# This policy provides the necessary permissions for
# an EC2 instance to communicate with AWS Systems Manager (SSM)
# and other services such as CloudWatch
resource "aws_iam_role_policy_attachment" "ssm_attachment" {
  role       = aws_iam_role.rr_ec2_s3_secret_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" # Managed policy ARN
}



