output "bastion_public_ip" {
  description = "The public IP address of the bastion host for SSH access."
  value       = module.compute.bastion_public_ip
}

output "nomad_server_private_ip" {
  description = "The private IP address of the Nomad server."
  value       = module.compute.nomad_server_private_ip
}

output "hello_world_app_url" {
  description = "The URL of the deployed hello-world application."
  value       = "http://${module.compute.alb_dns_name}"
}

output "ssh_tunnel_command" {
  description = "The command to establish an SSH tunnel to the Nomad server UI."
  value       = "ssh -i <your-ssh-key.pem> -N -L 4646:${module.compute.nomad_server_private_ip}:4646 ec2-user@${module.compute.bastion_public_ip}"
}