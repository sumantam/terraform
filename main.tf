variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "ssh_public_key_path" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "ssh_private_key_path" {
  description = "The AWS region to deploy resources in"
  type        = string
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  access_key = "AKIA4SDNVV6HUBN77MU4"
  secret_key = "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"
  region = "us-east-1"
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow inbound SSH traffic"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Or specify your IP range instead of 0.0.0.0/0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Ingress rule for HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allows HTTP traffic from anywhere
  }

  # Ingress rule for HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allows HTTPS traffic from anywhere
  }

# Ingress rule for your app (port 3000)
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allows traffic to port 3000 from anywhere
  }

  # Ingress rule for ICMP (ping)
  ingress {
    from_port   = -1    # ICMP type code for all types
    to_port     = -1    # ICMP type code for all codes
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]  # Allows ICMP (ping) from anywhere
  }

  # Egress rule (outbound traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allows all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ExampleAppServerSecurity"
  }
}

resource "aws_instance" "app_server" {
  ami           = "ami-0df8c184d5f6ae949"
  instance_type = "t2.small"
  associate_public_ip_address = true
  # security_groups = ["allow_ssh"]
  security_groups = [
    "default",                             # This is a default security group, an existing one
    aws_security_group.allow_ssh.name      # This references the security group created by Terraform
  ]

  tags = {
    Name = "ExampleAppServerInstance"
  }
  user_data = <<-EOF
	#!/bin/bash
	#set -e
	echo "root:hubspotpass" | chpasswd
	echo "Starting user data script" > /var/log/user-data.log
	# Update packages
	
	echo "Running yum update" >> /var/log/user-data.log
	yum update -y >> /var/log/user-data.log 2>&1
	INSTALL_STATUS=$?
	echo "yum install returned status: $INSTALL_STATUS" >> /var/log/user-data.log
	
	if [ $INSTALL_STATUS -ne 0 ]; then
  		echo "yum update failed" >> /var/log/user-data.log
	else
  		echo "yum update completed successfully" >> /var/log/user-data.log
	fi
	
	echo "Installing ec2-instance-connect" >> /var/log/user-data.log

	yum install -y ec2-instance-connect >> /var/log/user-data.log 2>&1
	INSTALL_STATUS=$?
	echo "yum ec2-instance-connect returned status: $INSTALL_STATUS" >> /var/log/user-data.log
	
	if [ $INSTALL_STATUS -ne 0 ]; then
  		echo "ec2-instance-connect installation failed" >> /var/log/user-data.log
	else
  		echo "ec2-instance-connect installed successfully" >> /var/log/user-data.log
	fi
	
	echo "Ending user data script ec2 Instance Connect" > /var/log/user-data.log
	
	# Create the application directory and change to it
	mkdir -p /home/ec2-user/myapp >> /var/log/user-data.log 2>&1
	cd /home/ec2-user/myapp
	curl -sL https://rpm.nodesource.com/setup_16.x | sudo bash -
	yum install -y nodejs >> /var/log/user-data.log 2>&1
	echo "User data script installed nodejs" >> /var/log/user-data.log

        yum install -y git
	echo "User git installation completed" >> /var/log/user-data.log
        yum install -y nodejs npm
	git clone https://github.com/sumantam/StripeApp.git
        cd StripeApp/publicApp
        npm install
        node index.js
	echo "User data script completed" >> /var/log/user-data.log
	EOF

}

#resource "aws_instance" "my_instance" {
#  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI (you may need to change this)
#  instance_type = "t2.micro"
#
#  key_name = "your-ssh-key"  # Replace with your actual key pair name
#
#  security_groups = ["your-security-group"]  # Replace with your security group name or ID
#
#  tags = {
#    Name = "MyAppInstance"
#  }
#
#  # User data script to clone the Git repository
#  user_data = <<-EOF
#              #!/bin/bash
#              yum update -y
#              yum install -y git
#              yum install -y nodejs npm
#              cd /home/ec2-user
#              git clone https://github.com/yourusername/yourrepository.git
#              cd yourrepository
#              npm install
#              node index.js
#              EOF
#
#  # Optional: Use a remote-exec provisioner to run commands
#  provisioner "remote-exec" {
#    inline = [
#      "cd /home/ec2-user/yourrepository",
#      "npm install",
#      "node index.js"
#    ]
#
#    connection {
#      type        = "ssh"
#      user        = "ec2-user"
#      private_key = file("path-to-your-private-key.pem")  # Path to your private key
#      host        = self.public_ip
#    }
#  }
#}
#
#output "public_ip" {
#  value = aws_instance.my_instance.public_ip
#}

# Use the file provisioner to upload your local application
# resource "null_resource" "upload_app" {
#  depends_on = [aws_instance.app_server]
#
#	provisioner "file" {
#  		source      = "../src/publicApp/*"  
#  		destination = "/home/ec2-user/myapp" 
#	}
#}

#resource "null_resource" "upload_app" {
#  depends_on = [aws_instance.app_server]
#
#  provisioner "local-exec" {
#    command = <<EOT
#      # Send the SSH public key using EC2 Instance Connect
#      aws ec2-instance-connect send-ssh-public-key \
#        --region ${var.region} \
#        --instance-id ${aws_instance.app_server.id} \
#        --availability-zone ${aws_instance.app_server.availability_zone} \
#        --instance-os-user ec2-user \
#        --ssh-public-key file://${var.ssh_public_key_path}
#
#      # Use SCP to transfer the files to the EC2 instance
#      scp -o StrictHostKeyChecking=no \
#        -r ../src/publicApp/* ec2-user@${aws_instance.app_server.public_ip}:/home/ec2-user/myapp
#    EOT
#  }
#}
