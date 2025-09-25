
resource "aws_security_group" "bastion" {
  name        = "${var.cluster_name}-bastion-sg"
  description = "Bastion Host Security Group"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.cluster_name}-bastion-sg" }
}

resource "aws_security_group" "nomad_server" {
  name        = "${var.cluster_name}-server-sg"
  description = "Nomad Server Security Group"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.cluster_name}-server-sg" }
}

resource "aws_security_group" "nomad_client" {
  name        = "${var.cluster_name}-client-sg"
  description = "Nomad Client Security Group"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.cluster_name}-client-sg" }
}

resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Application Load Balancer Security Group"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.cluster_name}-alb-sg" }
}


resource "aws_security_group_rule" "bastion_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "server_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nomad_server.id
}

resource "aws_security_group_rule" "client_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nomad_client.id
}

resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}


resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  description       = "Allow HTTP from anywhere"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}


resource "aws_security_group_rule" "bastion_ingress_ssh" {
  type              = "ingress"
  description       = "Allow SSH from users IP"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ssh_cidr
  security_group_id = aws_security_group.bastion.id
}


resource "aws_security_group_rule" "server_ingress_ssh_from_bastion" {
  type                     = "ingress"
  description              = "Allow SSH from Bastion"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.nomad_server.id
}

resource "aws_security_group_rule" "server_ingress_ui_from_bastion" {
  type                     = "ingress"
  description              = "Allow Nomad UI access from Bastion"
  from_port                = 4646
  to_port                  = 4646
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.nomad_server.id
}

resource "aws_security_group_rule" "server_ingress_nomad_from_vpc" {
  type              = "ingress"
  description       = "Allow Nomad agent traffic from within the VPC"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1" # TCP and UDP
  cidr_blocks       = ["10.0.0.0/16"] # <-- CYCLE BREAKER
  security_group_id = aws_security_group.nomad_server.id
}


resource "aws_security_group_rule" "client_ingress_ssh_from_bastion" {
  type                     = "ingress"
  description              = "Allow SSH from Bastion"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.nomad_client.id
}

resource "aws_security_group_rule" "client_ingress_app_from_alb" {
  type                     = "ingress"
  description              = "Allow App traffic from ALB for health checks and requests"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.nomad_client.id
}

resource "aws_security_group_rule" "client_ingress_nomad_from_vpc" {
  type              = "ingress"
  description       = "Allow Nomad agent traffic from within the VPC"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1" # TCP and UDP
  cidr_blocks       = ["10.0.0.0/16"] # <-- CYCLE BREAKER
  security_group_id = aws_security_group.nomad_client.id
}
