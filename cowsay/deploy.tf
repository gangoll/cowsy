provider "aws" {
  access_key = "AKIAIVBVLQZXPF44XYLQ"
  secret_key = "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"
  region  = "eu-central-1"
  
}

resource "aws_vpc" "cowsay" {
  cidr_block = "10.0.0.0/16"
  tags = {
    name = "cowsay"
  }
}
resource "aws_subnet" "cowsay" {
  vpc_id     = aws_vpc.cowsay.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "cowsay"
  }
}
resource "aws_internet_gateway" "cowsayGw" {
  vpc_id = aws_vpc.cowsay.id

  tags = {
    Name = "cowsay"
  }
}
resource "aws_security_group" "cowsay" {
  name        = "cowsay"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.cowsay.id

  ingress {
    description = "TLS from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
   description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
   description = "all"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  

   
  tags = {
    Name = "cowsay"
  }
}

resource "aws_route_table" "cowsay" {
  vpc_id = aws_vpc.cowsay.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cowsayGw.id
  }
  tags = {
    Name = "cowsay"
  }
}
resource "aws_route_table_association" "cowsay" {
  subnet_id  = aws_subnet.cowsay.id
  route_table_id = aws_route_table.cowsay.id

}

resource "aws_instance" "cowsay" {
  ami = "ami-0502e817a62226e03"
 instance_type = "t2.micro"
 subnet_id  = aws_subnet.cowsay.id
 associate_public_ip_address = true
 security_groups = ["${aws_security_group.cowsay.id}"]
 key_name = "key"
 tags = {
    Name = "cowsay"
    }
 connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = file("key.pem")
    host     = aws_instance.cowsay.public_ip
  }

provisioner "file" {
    source      = "npm_installation.sh"
    destination = "/tmp/npm_installation.sh"
  }
  provisioner "file" {
    source      = "src"
    destination = "/tmp/"
  }
   

   provisioner "remote-exec" {
    inline = [
    
     "sudo chmod 777 /tmp/npm_installation.sh",
     "sudo /tmp/npm_installation.sh",
     "npm start",

    ]
    
  }

  
   
}


output "instance_ip" {
  description = "The public ip for ssh access"
  value       = aws_instance.cowsay.public_ip
  
}