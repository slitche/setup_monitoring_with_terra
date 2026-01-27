# Security Group
resource "aws_security_group" "loki-sg" {
  name        = "loki-sg"
  description = "loki security group"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }


  ingress {
    description     = "Connection to Loki from grafana server|view logs"
    from_port       = 3100
    to_port         = 3100
    protocol        = "tcp"
    security_groups = [aws_security_group.grafana-sg.id]
  }

  ingress {
    description     = "Connection to Loki from app server|upload logs"
    from_port       = 3100
    to_port         = 3100
    protocol        = "tcp"
    security_groups = [aws_security_group.app-sg.id]
  }

  ingress {
    description     = "Connection to Loki from my IP"
    from_port       = 3100
    to_port         = 3100
    protocol        = "tcp"
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
resource "aws_instance" "loki-server" {
  ami                    = var.ami
  instance_type          = var.instance-type
  key_name               = "monitoring_keypair" # Ensure this key pair exists in your AWS account
  vpc_security_group_ids = [aws_security_group.loki-sg.id]
  user_data              = file("./setup_scripts/loki-setup.sh")
  tags = {
    Name = "loki-Server"
  }
}


# public IP
output "loki_public_ip" {
  value = aws_instance.loki-server.public_ip
}

# private IP
output "loki_private_ip" {
  value = aws_instance.loki-server.private_ip
}

