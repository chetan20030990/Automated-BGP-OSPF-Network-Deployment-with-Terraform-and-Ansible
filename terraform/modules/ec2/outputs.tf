output "r1_public_ip"  { value = aws_instance.r1.public_ip }
output "r2_public_ip"  { value = aws_instance.r2.public_ip }
output "r3_public_ip"  { value = aws_instance.r3.public_ip }
output "r1_private_ip" { value = aws_instance.r1.private_ip }
output "r2_private_ip" { value = aws_instance.r2.private_ip }
output "r3_private_ip" { value = aws_instance.r3.private_ip }
