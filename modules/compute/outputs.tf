output "bastion_public_ip" { value = aws_instance.bastion.public_ip }
output "nomad_server_private_ip" { value = aws_instance.nomad_server.private_ip }
output "alb_dns_name" { value = aws_lb.main.dns_name }