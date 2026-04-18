#!/bin/bash
# generate_inventory.sh — Run this after `terraform apply` to auto-populate Ansible inventory
# Usage: cd terraform && bash ../scripts/generate_inventory.sh

set -e

R1=$(terraform output -raw r1_public_ip)
R2=$(terraform output -raw r2_public_ip)
R3=$(terraform output -raw r3_public_ip)

KEY="~/.ssh/bgp-ospf-key.pem"

cat > ../ansible/inventory/hosts.ini << EOF
[r1]
R1 ansible_host=${R1}

[r2]
R2 ansible_host=${R2}

[r3]
R3 ansible_host=${R3}

[as100]
R1 ansible_host=${R1}
R2 ansible_host=${R2}

[as200]
R3 ansible_host=${R3}

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=${KEY}
ansible_ssh_common_args="-o StrictHostKeyChecking=no"
EOF

# Also update verify_network.py with real IPs
sed -i '' "s/FILL_IN_R1_PUBLIC_IP/${R1}/" ../scripts/verify_network.py
sed -i '' "s/FILL_IN_R2_PUBLIC_IP/${R2}/" ../scripts/verify_network.py
sed -i '' "s/FILL_IN_R3_PUBLIC_IP/${R3}/" ../scripts/verify_network.py

echo "✅ Inventory generated:"
cat ../ansible/inventory/hosts.ini
