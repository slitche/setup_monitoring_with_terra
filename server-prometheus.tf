
# Security Group
resource "aws_security_group" "prometheus-sg" {
  name        = "prometheus-sg"
  description = "Prometheus security group"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  ingress {
    description = "Prometheus Web UI"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  ingress {
    description     = "Connection from Grafana to Prometheus"
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [aws_security_group.grafana-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# EC2 Instance
resource "aws_instance" "prometheus-server" {
  ami                    = var.ami
  instance_type          = var.instance-type
  key_name               = "monitoring_keypair" # Ensure this key pair exists in your AWS account
  vpc_security_group_ids = [aws_security_group.prometheus-sg.id]
  user_data              = file("./setup_scripts/prometheus-setup.sh")
  tags = {
    Name = "Prometheus-Server"
  }
}


# public IP
output "prometheus_public_ip" {
  value = aws_instance.prometheus-server.public_ip
}

# private IP
output "prometheus_private_ip" {
  value = aws_instance.prometheus-server.private_ip
}

