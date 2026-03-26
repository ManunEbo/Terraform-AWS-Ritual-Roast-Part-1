# 5. Load Balancer Setup
resource "aws_lb" "rr_alb" {
  name               = "rr-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.LoadBalancer-SG.id]
  subnets            = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id]

  enable_deletion_protection = false

  tags = merge(local.common_tags, {
    Name = "rr-alb"
  })
}


# Creating the target group with a dedicated health check path
resource "aws_lb_target_group" "rr_alb_tgt_group" {
  name     = "rr-alb-tgt-group"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.RR-VPC.id

  health_check {
    # This matches the @app.route('/health') we added to ritual-roast.py
    path                = "/health"
    protocol            = "HTTP"
    port                = "5000"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = merge(local.common_tags, {
    Name = "rr-alb-tgt-group"
  })
}

resource "aws_lb_listener" "rr_alb_listener" {
  load_balancer_arn = aws_lb.rr_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rr_alb_tgt_group.arn
  }
}