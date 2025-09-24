output "bastion_sg_id" { value = aws_security_group.bastion.id }
output "nomad_server_sg_id" { value = aws_security_group.nomad_server.id }
output "nomad_client_sg_id" { value = aws_security_group.nomad_client.id }
output "alb_sg_id" { value = aws_security_group.alb.id }