resource "aws_default_vpc" "default" {
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-east-1a"
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "us-east-1b"
}

resource "aws_default_subnet" "default_az3" {
  availability_zone = "us-east-1c"
}

resource "aws_default_subnet" "default_az4" {
  availability_zone = "us-east-1d"
}

resource "aws_default_subnet" "default_az5" {
  availability_zone = "us-east-1e"
}

resource "aws_default_subnet" "default_az6" {
  availability_zone = "us-east-1f"
}

resource "aws_security_group" "alb_security_group" {
  name = "alb_security_group"

  # HTTP inbound
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS outbound
  egress {
    from_port   = 0
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# create target group
resource "aws_lb_target_group" "foo_tg" {
  name     = "foo-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id

  health_check {
    enabled = true
    matcher = 200 # the HTTP or gRPC codes to use when checking for a successful response from a target
    protocol = "HTTP"
    interval            = 10 # approximate amount of time, in seconds, between health checks of an individual target
    path                = "/" # destination for the health check request
    timeout             = 3 # amount of time, in seconds, during which no response from a target means a failed health check
    healthy_threshold   = 3 # number of consecutive health check successes required before considering a target healthy
    unhealthy_threshold = 2 # number of consecutive health check failures required before considering a target unhealthy
    port                = 80
  }
}

# target group attachment for app_server_1
resource "aws_lb_target_group_attachment" "app1_tg_attachment" {
  target_group_arn = aws_lb_target_group.foo_tg.arn
  target_id        = aws_instance.app_server_1.id
  port             = 80
}

# target group attachment for app_server_2
resource "aws_lb_target_group_attachment" "app2_tg_attachment" {
  target_group_arn = aws_lb_target_group.foo_tg.arn
  target_id        = aws_instance.app_server_2.id
  port             = 80
}

# listener
resource "aws_lb_listener" "my_alb_listener" {
  load_balancer_arn = aws_lb.foo_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.foo_tg.arn
  }
}

# application load balancer (take a few minutes to be made)
resource "aws_lb" "foo_alb" {
  name               = "foo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets            = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id, aws_default_subnet.default_az3.id, aws_default_subnet.default_az4.id, aws_default_subnet.default_az5.id, aws_default_subnet.default_az6.id]

  tags = {
    Name = "Foo_ALB"
  }
}
