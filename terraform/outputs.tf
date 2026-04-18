output "r1_public_ip" {
  description = "Public IP of Router 1"
  value       = module.ec2.r1_public_ip
}

output "r2_public_ip" {
  description = "Public IP of Router 2"
  value       = module.ec2.r2_public_ip
}

output "r3_public_ip" {
  description = "Public IP of Router 3"
  value       = module.ec2.r3_public_ip
}

output "r1_private_ip" {
  description = "Private IP of Router 1"
  value       = module.ec2.r1_private_ip
}

output "r2_private_ip" {
  description = "Private IP of Router 2"
  value       = module.ec2.r2_private_ip
}

output "r3_private_ip" {
  description = "Private IP of Router 3"
  value       = module.ec2.r3_private_ip
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "subnet_a_id" {
  description = "Subnet A ID"
  value       = module.vpc.subnet_a_id
}

output "subnet_b_id" {
  description = "Subnet B ID"
  value       = module.vpc.subnet_b_id
}

output "subnet_c_id" {
  description = "Subnet C ID"
  value       = module.vpc.subnet_c_id
}
