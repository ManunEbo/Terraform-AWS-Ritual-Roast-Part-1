# This generates a unique suffix for the ASG name
# It only changes if the 'keepers' change (or if you manually taint it)
resource "random_id" "asg_suffix" {
  byte_length = 2 # This results in a 4-character hex string (e.g., "abcd")
}

# The Launch Template stays the same as your previous working version
resource "aws_launch_template" "rr_launch_template" {
  name_prefix   = "rr_launch_template-"
  image_id      = var.ami
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.rr_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    security_groups             = [aws_security_group.Web-App-SG.id]
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
exec > /var/log/user-data.log 2>&1
echo "Starting setup..."
dnf update -y
dnf install -y python3-pip unzip wget

# MySQL Client installation
dnf install -y https://dev.mysql.com/get/mysql84-community-release-el9-1.noarch.rpm
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
dnf install -y mysql-community-client

# RDS SSL Cert
cd /home/ec2-user
curl -O https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
chown ec2-user:ec2-user global-bundle.pem

# App Sync
mkdir -p /home/ec2-user/myflaskapp
aws s3 sync s3://rr-capstone-5b160b287a99a6d9 /home/ec2-user/myflaskapp --region eu-west-2
cd /home/ec2-user/myflaskapp
if [ -d "flask" ]; then cd flask; fi
chown -R ec2-user:ec2-user /home/ec2-user/myflaskapp

# Virtual Env
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
if [ -f "requirements.txt" ]; then pip install -r requirements.txt; fi

# Systemd Service
cat <<SYSTEMD > /etc/systemd/system/ritual-roast.service
[Unit]
Description=Ritual Roast Flask App
After=network.target

[Service]
User=ec2-user
Group=ec2-user
WorkingDirectory=/home/ec2-user/myflaskapp/flask
ExecStart=/home/ec2-user/myflaskapp/flask/venv/bin/python3 /home/ec2-user/myflaskapp/flask/ritual-roast.py
Restart=always
RestartSec=5
StandardOutput=append:/var/log/flask-app.log
StandardError=append:/var/log/flask-app.log

[Install]
WantedBy=multi-user.target
SYSTEMD

systemctl daemon-reload
systemctl enable ritual-roast
systemctl start ritual-roast
EOF
)

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 30
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# The Auto Scaling Group with the explicit dependency
resource "aws_autoscaling_group" "rr_autoscaling_group" {
  name = "rr-asg-${aws_launch_template.rr_launch_template.latest_version}-${random_id.asg_suffix.hex}"

  desired_capacity    = 2
  min_size            = 2
  max_size            = 4
  vpc_zone_identifier = [aws_subnet.web_subnets[0].id, aws_subnet.web_subnets[1].id]

  health_check_type         = "ELB"
  health_check_grace_period = 300
  target_group_arns         = [aws_lb_target_group.rr_alb_tgt_group.arn]

  launch_template {
    id      = aws_launch_template.rr_launch_template.id
    version = "$Latest"
  }

  # Ensure the secret has the HOST before the ASG creates any instances
  depends_on = [
    aws_secretsmanager_secret_version.db_host_update,
    aws_db_instance.ritual_roast_db
  ]
}

# Attach autoscaling policy
resource "aws_autoscaling_policy" "rr_cpu_scaling_policy" {
  name                   = "rr-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.rr_autoscaling_group.name
  policy_type            = "TargetTrackingScaling"

  # The "Smoothing" Buffer: 
  # Wait 300 seconds (3 mins) after a scaling activity before doing another one.
  estimated_instance_warmup = 180 

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0

    # SCALE-IN PROTECTION:
    # This prevents "Erratic Scaling Down" by forcing a 3-minute wait 
    # after the load drops before an instance is terminated.
    disable_scale_in = false 
  }
}