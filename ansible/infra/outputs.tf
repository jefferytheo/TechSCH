output "ansible_servers_ip" {
  description = "AWS Instance IP"
  value       = [for instance in aws_instance.ansible_servers : instance.public_ip]
}