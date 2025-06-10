# This Terraform configuration reads the default VPC and its subnets, which are used on the other resources.

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

data "aws_subnet" "subnet" {
  for_each = toset(data.aws_subnets.default_subnets.ids)
  id       = each.value
}
