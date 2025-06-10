variable "aws_region" {
  description = "The AWS region to deploy the EC2 instances."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "The prefix to be used for all resources."
  type        = string
}

variable "default_tags" {
  description = "The default tags to be applied to all resources."
  type        = map(string)
  default = {
    "terraform" = "true"
    "group"     = "E"
    "lab"       = "workshop"
  }
}

variable "enable_icmp_ingress" {
  description = "Whether to allow ICMP ingress traffic."
  type        = bool
  default     = false
  nullable    = false
}

variable "container_image" {
  description = "The Docker image to be used for the ECS task."
  type        = string
  default     = "ghcr.io/traefik/whoami:v1.11"
}
