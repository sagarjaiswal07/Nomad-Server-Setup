module "networking" {
  source       = "./modules/networking"
  cluster_name = var.cluster_name
}

module "security" {
  source           = "./modules/security"
  cluster_name     = var.cluster_name
  vpc_id           = module.networking.vpc_id
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

module "compute" {
  source             = "./modules/compute"
  cluster_name       = var.cluster_name
  ssh_key_name       = var.ssh_key_name
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  client_nodes_count = var.client_nodes_count
  vpc_id             = module.networking.vpc_id

  # Pass the outputs from the security module INTO the compute module
  bastion_sg_id      = module.security.bastion_sg_id
  nomad_server_sg_id = module.security.nomad_server_sg_id
  nomad_client_sg_id = module.security.nomad_client_sg_id
  alb_sg_id          = module.security.alb_sg_id

  # Explicit dependency to ensure networking and security are fully up
  depends_on = [module.networking, module.security]
}