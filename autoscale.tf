# 1. Create the Instance Profile
resource "aws_iam_instance_profile" "rr_instance_profile" {
  name = "rr_ec2_s3_secret_role_profile"
  role = "rr_ec2_s3_secret_role"
}

# 2. Updated Launch Template
# resource "aws_launch_template" "rr_launch_template" {
#   name_prefix   = "rr_launch_template-"
#   image_id      = var.ami
#   instance_type = var.instance_type

#   iam_instance_profile {
#     name = aws_iam_instance_profile.rr_instance_profile.name
#   }

#   network_interfaces {
#     associate_public_ip_address = var.associate_public_ip_address
#     security_groups             = [aws_security_group.Web-App-SG.id]
#   }

#   # The hyphen in <<-EOF tells Terraform to strip leading whitespace/indentation
#   user_data = base64encode(<<-EOF
#     #!/bin/bash
#     # Redirect all output to log files for debugging
#     exec > /var/log/user-data.log 2>&1

#     echo "Starting setup..."
#     sudo yum update -y
#     sudo yum install -y python3-pip unzip

#     # Create app directory
#     mkdir -p /home/ec2-user/myflaskapp
#     echo "Syncing from S3..."
#     aws s3 sync s3://rr-capstone-5b160b287a99a6d9 /home/ec2-user/myflaskapp --region eu-west-2

#     # Navigate to the app folder
#     cd /home/ec2-user/myflaskapp

#     # Check if 'flask' folder exists and enter it
#     if [ -d "flask" ]; then
#         cd flask
#     fi

#     echo "Current Directory: $(pwd)"
#     ls -lah

#     # 1. Create a Virtual Environment
#     python3 -m venv venv
#     source venv/bin/activate

#     # 2. Install requirements inside the virtual environment
#     pip install --upgrade pip
#     if [ -f "requirements.txt" ]; then
#         pip install -r requirements.txt
#     else
#         echo "ERROR: requirements.txt not found!"
#         exit 1
#     fi

#     # 3. Start the Flask app
#     # Ensure your python code uses app.run(host='0.0.0.0', port=5000)
#     nohup python3 ritual-roast.py > /var/log/flask-app.log 2>&1 &

#     echo "Setup completed successfully!"
#   EOF
#   )

#   # Added block device mapping to ensure you have the 30GB you saw in df -h
#   block_device_mappings {
#     device_name = "/dev/xvda"
#     ebs {
#       volume_size           = 30
#       volume_type           = "gp3"
#       delete_on_termination = true
#     }
#   }

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = merge(local.common_tags, {
#     Name = "rr_launch_template"
#   })
# }

# resource "aws_launch_template" "rr_launch_template" {
#   name_prefix   = "rr_launch_template-"
#   image_id      = var.ami
#   instance_type = var.instance_type

#   iam_instance_profile {
#     name = aws_iam_instance_profile.rr_instance_profile.name
#   }

#   network_interfaces {
#     associate_public_ip_address = var.associate_public_ip_address
#     security_groups             = [aws_security_group.Web-App-SG.id]
#   }

#   user_data = base64encode(<<-EOF
#     #!/bin/bash
#     # Redirect all output to log files for debugging
#     exec > /var/log/user-data.log 2>&1

#     echo "Starting setup..."
#     # Update and install basic dependencies
#     dnf update -y
#     dnf install -y python3-pip unzip wget

#     # --- NEW: Install MySQL Community Client ---
#     echo "Installing MySQL Client..."
#     # 1. Install the MySQL 8.4 LTS repository (compatible with EL9/AL2023)
#     dnf install -y https://dev.mysql.com/get/mysql84-community-release-el9-1.noarch.rpm

#     # 2. Import the GPG key to trust the packages
#     rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023

#     # 3. Install the client
#     dnf install -y mysql-community-client

#     # --- NEW: Setup SSL Certificate for RDS ---
#     echo "Downloading RDS SSL certificate..."
#     cd /home/ec2-user
#     curl -O https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
#     chown ec2-user:ec2-user global-bundle.pem
#     # ------------------------------------------

#     # Create app directory
#     mkdir -p /home/ec2-user/myflaskapp
#     echo "Syncing from S3..."
#     aws s3 sync s3://rr-capstone-5b160b287a99a6d9 /home/ec2-user/myflaskapp --region eu-west-2

#     # Navigate to the app folder
#     cd /home/ec2-user/myflaskapp

#     # Check if 'flask' folder exists and enter it
#     if [ -d "flask" ]; then
#         cd flask
#     fi

#     echo "Current Directory: $(pwd)"
#     ls -lah

#     # 1. Create a Virtual Environment
#     python3 -m venv venv
#     source venv/bin/activate

#     # 2. Install requirements inside the virtual environment
#     pip install --upgrade pip
#     if [ -f "requirements.txt" ]; then
#         pip install -r requirements.txt
#     else
#         echo "ERROR: requirements.txt not found!"
#         exit 1
#     fi

#     # 3. Start the Flask app
#     # nohup ensures the app keeps running after the script finishes
#     nohup python3 ritual-roast.py > /var/log/flask-app.log 2>&1 &

#     echo "Setup completed successfully!"
#   EOF
#   )

#   block_device_mappings {
#     device_name = "/dev/xvda"
#     ebs {
#       volume_size           = 30
#       volume_type           = "gp3"
#       delete_on_termination = true
#     }
#   }

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = merge(local.common_tags, {
#     Name = "rr_launch_template"
#   })
# }


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
    # Redirect all output to log files for debugging
    exec > /var/log/user-data.log 2>&1

    echo "Starting setup..."
    # Update and install basic dependencies
    dnf update -y
    dnf install -y python3-pip unzip wget

    # --- NEW: Install MySQL Community Client ---
    echo "Installing MySQL Client..."
    # 1. Install the MySQL 8.4 LTS repository (compatible with EL9/AL2023)
    dnf install -y https://dev.mysql.com/get/mysql84-community-release-el9-1.noarch.rpm
    
    # 2. Import the GPG key to trust the packages
    rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
    
    # 3. Install the client
    dnf install -y mysql-community-client

    # --- NEW: Setup SSL Certificate for RDS ---
    echo "Downloading RDS SSL certificate..."
    cd /home/ec2-user
    curl -O https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
    chown ec2-user:ec2-user global-bundle.pem
    # ------------------------------------------

    # Create app directory
    mkdir -p /home/ec2-user/myflaskapp
    echo "Syncing from S3..."
    aws s3 sync s3://rr-capstone-5b160b287a99a6d9 /home/ec2-user/myflaskapp --region eu-west-2

    # Navigate to the app folder
    cd /home/ec2-user/myflaskapp

    # Check if 'flask' folder exists and enter it
    if [ -d "flask" ]; then
        cd flask
    fi

    # Fix directory permissions for ec2-user
    chown -R ec2-user:ec2-user /home/ec2-user/myflaskapp

    echo "Current Directory: $(pwd)"
    ls -lah

    # 1. Create a Virtual Environment
    python3 -m venv venv
    source venv/bin/activate

    # 2. Install requirements inside the virtual environment
    pip install --upgrade pip
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
    else
        echo "ERROR: requirements.txt not found!"
        exit 1
    fi

    # 3. Create the Systemd Service File
    # This ensures the app runs in the background and restarts on failure.
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

    # 4. Start the service
    echo "Starting Ritual Roast Service..."
    systemctl daemon-reload
    systemctl enable ritual-roast
    systemctl start ritual-roast

    echo "Setup completed successfully!"
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

  tags = merge(local.common_tags, {
    Name = "rr_launch_template"
  })
}


# 3. Auto Scaling Group

# Add this small resource at the top of your file
resource "random_id" "asg_suffix" {
  byte_length = 2
}

resource "aws_autoscaling_group" "rr_autoscaling_group" {
  # This keeps your versioning but adds a suffix like 'rr-asg-1-abcd'
  name = "rr-asg-${aws_launch_template.rr_launch_template.latest_version}-${random_id.asg_suffix.hex}"

  desired_capacity    = 2
  min_size            = 2
  max_size            = 4
  vpc_zone_identifier = [aws_subnet.web_subnets[0].id, aws_subnet.web_subnets[1].id]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  target_group_arns = [aws_lb_target_group.rr_alb_tgt_group.arn]

  launch_template {
    id      = aws_launch_template.rr_launch_template.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "rr-asg-instance"
    propagate_at_launch = true
  }
}

# 4. Scaling Policy
resource "aws_autoscaling_policy" "rr_autoscaling_policy" {
  name                      = "rr_autoscaling_policy"
  autoscaling_group_name    = aws_autoscaling_group.rr_autoscaling_group.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 180

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 40.0
  }
}