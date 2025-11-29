output "load_balancer_dns" {
  description = "The DNS name of the Application Load Balancer."
  value       = module.load_balancer.lb_dns_name
}
