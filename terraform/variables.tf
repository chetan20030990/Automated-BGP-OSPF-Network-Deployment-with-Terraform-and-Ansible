variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_a_cidr" {
  description = "Subnet A CIDR - R1 to R2 link"
  type        = string
  default     = "10.0.1.0/28"
}

variable "subnet_b_cidr" {
  description = "Subnet B CIDR - R1 to R3 eBGP link"
  type        = string
  default     = "10.0.2.0/28"
}

variable "subnet_c_cidr" {
  description = "Subnet C CIDR - R3 loopback/downstream"
  type        = string
  default     = "10.0.3.0/24"
}

variable "availability_zone" {
  description = "Availability zone for subnets"
  type        = string
  default     = "us-east-1a"
}

variable "ami_id" {
  description = "Amazon Linux 2 AMI ID"
  type        = string
  default     = "ami-0c02fb55956c7d316" # Amazon Linux 2 us-east-1; update if needed
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the AWS key pair to use for SSH"
  type        = string
}
