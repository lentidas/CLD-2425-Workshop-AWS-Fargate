output "load_balancer_dns_name" {
  description = "Public DNS name for the Application Load Balancer."
  value       = resource.aws_lb.load_balancer.dns_name
}
