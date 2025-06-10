# Create an Application Load Balancer (ALB) to route traffic to the ECS service.
# This load balancer is IPv4 only and on all the subnets in the default VPC.
resource "aws_lb" "load_balancer" {
  name               = "${var.name_prefix}-LB"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"

  security_groups = [
    resource.aws_security_group.ec2_security_group.id,
  ]

  subnets = data.aws_subnets.default_subnets.ids
}

# Create a target group for the load balancer to route traffic to the ECS service.
resource "aws_lb_target_group" "target_group" {
  name        = "${var.name_prefix}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.default_vpc.id

  health_check {
    healthy_threshold   = 2
    interval            = 10
    timeout             = 5
    unhealthy_threshold = 2
    path                = "/health" # Use the /health endpoint available in traefik/whoami image.
  }
}

# Create a listener for the load balancer to forward traffic to the target group.
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = resource.aws_lb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = resource.aws_lb_target_group.target_group.arn
  }
}
