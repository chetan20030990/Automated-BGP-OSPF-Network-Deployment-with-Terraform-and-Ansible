resource "aws_security_group" "router_sg" {
  vpc_id      = var.vpc_id
  name        = "router-sg"
  description = "Security group for FRR routers"

  # SSH from anywhere (management)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH management"
  }

  # BGP port 179 within VPC
  ingress {
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "BGP"
  }

  # OSPF protocol 89 within VPC
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "89"
    cidr_blocks = [var.vpc_cidr]
    description = "OSPF"
  }

  # ICMP within VPC (for pings)
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
    description = "ICMP ping"
  }

  # All outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "router-sg" }
}
