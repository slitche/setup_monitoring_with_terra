# Security Group
resource "aws_security_group" "grafana-sg" {
  name        = "grafana-sg"
  description = "grafana security group"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  ingress {
    description = "grafana Web UI"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# EC2 Instance
resource "aws_instance" "grafana-server" {
  ami                    = var.ami
  instance_type          = var.instance-type
  key_name               = "monitoring_keypair" # Ensure this key pair exists in your AWS account
  vpc_security_group_ids = [aws_security_group.grafana-sg.id]
  user_data              = file("./setup_scripts/grafana-setup.sh")
  tags = {
    Name = "grafana-Server"
  }
}


# public IP
output "grafana_public_ip" {
  value = aws_instance.grafana-server.public_ip
}

# private IP
output "grafana_private_ip" {
  value = aws_instance.grafana-server.private_ip
}

