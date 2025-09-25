data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  key_name               = var.ssh_key_name
  subnet_id              = var.public_subnet_ids[0]
  vpc_security_group_ids = [var.bastion_sg_id]
  tags                   = { Name = "${var.cluster_name}-bastion" }
}

resource "aws_instance" "nomad_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.small"
  key_name               = var.ssh_key_name
  subnet_id              = var.private_subnet_ids[0]
  vpc_security_group_ids = [var.nomad_server_sg_id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y yum-utils
              sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
              sudo yum -y install nomad
              sudo mkdir -p /etc/nomad.d && sudo chmod 700 /etc/nomad.d
              PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
              cat <<EOT > /etc/nomad.d/nomad.hcl
              datacenter = "dc1"
              data_dir = "/opt/nomad/data"
              server {
                enabled = true
                bootstrap_expect = 1
              }
              bind_addr = "0.0.0.0"
              advertise {
                  http = "$PRIVATE_IP"
                  rpc  = "$PRIVATE_IP"
                  serf = "$PRIVATE_IP"
              }
              EOT
              sudo systemctl enable nomad && sudo systemctl start nomad
              EOF

  tags = { Name = "${var.cluster_name}-nomad-server" }
}

resource "aws_launch_template" "nomad_client" {
  name_prefix            = "${var.cluster_name}-client-"
  image_id               = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [var.nomad_client_sg_id]

  depends_on = [aws_instance.nomad_server] 

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y yum-utils docker
              sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
              sudo yum -y install nomad
              sudo systemctl enable docker && sudo systemctl start docker
              sudo usermod -a -G docker ec2-user
              sudo mkdir -p /etc/nomad.d && sudo chmod 700 /etc/nomad.d
              cat <<EOT > /etc/nomad.d/nomad.hcl
              datacenter = "dc1"
              data_dir = "/opt/nomad/data"
              client {
                  enabled = true
                  servers = ["${aws_instance.nomad_server.private_ip}"]
              }
              EOT
              sudo systemctl enable nomad && sudo systemctl start nomad
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.cluster_name}-nomad-client" }
  }
}

resource "aws_autoscaling_group" "nomad_client" {
  name                = "${var.cluster_name}-client-asg"
  desired_capacity    = var.client_nodes_count
  max_size            = 5
  min_size            = 1
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.main.arn]

  launch_template {
    id      = aws_launch_template.nomad_client.id
    version = "$Latest"
  }
}

resource "aws_lb" "main" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "main" {
  name        = "${var.cluster_name}-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
