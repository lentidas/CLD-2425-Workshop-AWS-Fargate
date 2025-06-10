# These resource configurations create a security group for the ALB to allow incoming traffic (IPv4 and IPv6) 
# on port 80 and 443 (and ICMP if enabled).

resource "aws_security_group" "ec2_security_group" {
  name        = "${var.name_prefix}-default-sg"
  description = "Security group to allow ingress traffic to the EC2 instances"
  vpc_id      = data.aws_vpc.default_vpc.id
}

locals {
  ec2_allow_ingress_ports = toset(["80", "443"])
}

resource "aws_vpc_security_group_ingress_rule" "ec2_allow_ingress_ipv4" {
  for_each = local.ec2_allow_ingress_ports

  security_group_id = aws_security_group.ec2_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = each.key
  to_port           = each.key
}

resource "aws_vpc_security_group_ingress_rule" "ec2_allow_ingress_ipv6" {
  for_each = local.ec2_allow_ingress_ports

  security_group_id = aws_security_group.ec2_security_group.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "tcp"
  from_port         = each.key
  to_port           = each.key
}

resource "aws_vpc_security_group_ingress_rule" "allow_ingress_ipv4_icmp" {
  count = var.enable_icmp_ingress ? 1 : 0

  security_group_id = aws_security_group.ec2_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
}

resource "aws_vpc_security_group_ingress_rule" "ec2_allow_ingress_ipv6_icmp" {
  count = var.enable_icmp_ingress ? 1 : 0

  security_group_id = aws_security_group.ec2_security_group.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
}

resource "aws_vpc_security_group_egress_rule" "ec2_allow_egress_ipv4" {
  security_group_id = aws_security_group.ec2_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "ec2_allow_egress_ipv6" {
  security_group_id = aws_security_group.ec2_security_group.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
