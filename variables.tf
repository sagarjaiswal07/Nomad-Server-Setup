variable "aws_region" {
  description = "The AWS region to deploy the infrastructure in."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "A unique name for the Nomad cluster and its resources."
  type        = string
}

variable "ssh_key_name" {
  description = "The name of the EC2 key pair to use for SSH access (must exist in the specified AWS region)."
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "A list of CIDR blocks allowed to SSH into the bastion host. Example: [\"1.2.3.4/32\"]."
  type        = list(string)
}

variable "client_nodes_count" {
  description = "The desired number of Nomad client nodes to run in the Auto Scaling Group."
  type        = number
  default     = 2
}