locals {
  user_data = <<-EOF
    #!/bin/bash
    # Install FRRouting on Amazon Linux 2
    amazon-linux-extras install epel -y
    yum install -y frr frr-pythontools

    # Enable OSPF and BGP daemons
    sed -i 's/ospfd=no/ospfd=yes/' /etc/frr/daemons
    sed -i 's/bgpd=no/bgpd=yes/'   /etc/frr/daemons

    # Enable IP forwarding
    sysctl -w net.ipv4.ip_forward=1
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

    # Enable and start FRR
    systemctl enable frr
    systemctl start frr
  EOF
}

# Router 1 — AS 100, sits on Subnet A (R1-R2) and Subnet B (R1-R3 eBGP)
resource "aws_instance" "r1" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_a_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  source_dest_check           = false   # CRITICAL: allows routing
  user_data                   = local.user_data

  tags = { Name = "R1-AS100" }
}

# Router 2 — AS 100, sits on Subnet A (R1-R2 OSPF link)
resource "aws_instance" "r2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_a_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  source_dest_check           = false
  user_data                   = local.user_data

  tags = { Name = "R2-AS100" }
}

# Router 3 — AS 200, sits on Subnet B (eBGP link) and Subnet C (downstream)
resource "aws_instance" "r3" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_b_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  source_dest_check           = false
  user_data                   = local.user_data

  tags = { Name = "R3-AS200" }
}
