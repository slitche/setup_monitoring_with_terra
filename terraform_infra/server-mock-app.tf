# Security Group
resource "aws_security_group" "app-sg" {
  name        = "app-sg"
  description = "app security groups"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }


  # ingress {
  #   description = "HTTP"
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  # }

  # ingress {
  #   description = "HTTPS"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  # }


  ingress {
    description = "app Web UI - Flask Default Port"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  ingress {
    description     = "metrics access for Prometheus"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.prometheus-sg.id]
  }

  ingress {
    description = "Prometheus Node Exporter Web UI"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }


  ingress {
    description     = "Prometheus Node Exporter - scrape target"
    from_port       = 9100
    to_port         = 9100
    protocol        = "tcp"
    security_groups = [aws_security_group.prometheus-sg.id]
  }

  ingress {
    description = "Alloy-Loki Web UI"
    from_port   = 12345
    to_port     = 12345
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
resource "aws_instance" "app-server" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = "monitoring_keypair" # Ensure this key pair exists in your AWS account
  vpc_security_group_ids = [aws_security_group.app-sg.id]
  user_data              = file("../setup_scripts/test_app_server/mock_app-setup.sh")

  tags = {
    Name = "app-Server"
  }
}



# Setting up Alloy and Loki
resource "null_resource" "copy_and_run" {
  depends_on = [aws_instance.app-server]

  #trigger will re-run the copy_and_run if instance changes
  triggers = {
    instance_id = aws_instance.app-server.id
  }
  # Define the SSH connection once
  connection {
    type        = "ssh"
    user        = "ubuntu" # or ec2-user depending on your AMI
    private_key = var.ssh_private_key
    host        = aws_instance.app-server.public_ip
  }

  # Upload the script.. manually run the script after the terraform run because we have problems with the interactive parts
  provisioner "file" {
    source      = "../setup_scripts/test_app_server"
    destination = "/tmp/test_app_server"
  }


  # setup monitoring
  # Upload the script..
  provisioner "file" {
    source      = "./setup_scripts/monitor_app_server-setup.sh"
    destination = "/tmp/test_app_server/monitor_app_server-setup.sh"
  }

  # # Run the script remotely
  # provisioner "remote-exec" {
  #   inline = [
  #     "chmod +x /tmp/monitor_app_server-setup.sh",
  #     "sudo /tmp/monitor_app_server-setup.sh"
  #   ]
  # }
}





# public IP
output "app_public_ip" {
  value = aws_instance.app-server.public_ip
}

# private IP
output "app_private_ip" {
  value = aws_instance.app-server.private_ip
}

