# Outputs the AMI ID to the console 
output "amazon_linux_2023_ami_id" {
  value = data.aws_ami.amazon_linux_2023.id
}

# Output the ec2 s3 secret manager role
output "rr_ec2_s3_secret_role" {
  value = aws_iam_role.rr_ec2_s3_secret_role.name
}

# output the ".Web-App-SG" security group id
output "retrieved-Web-App-SG-id" {
  value = data.aws_security_group.Web-App-SG.id
}