provider "aws" {
  access_key = "AKIAI4AEYRZY3KHXDWFQ"
  secret_key = "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"
  region  = "eu-central-1"
  
}

resource "aws_vpc" "cowsay" {
  cidr_block = "10.0.0.0/16"
  tags = {
    name = "cowsay"
  }
}
resource "aws_subnet" "cowsay_private" {
  vpc_id     = aws_vpc.cowsay.id
  cidr_block = "10.0.10.0/24"
  }

resource "aws_subnet" "nginx" {
  vpc_id     = aws_vpc.cowsay.id
  cidr_block = "10.0.20.0/24"

  tags = {
    Name = "nginx"
  }
}
resource "aws_eip" "eip" {
  
  vpc      = true
}
resource "aws_s3_bucket" "src" {
  bucket = "cowsay-src"
  acl    = "private"

  tags = {
    Name        = "src"
  }
}

resource "aws_s3_bucket_object" "file_upload" {
  for_each = fileset("./", "src.*")
  bucket = "${aws_s3_bucket.src.id}"
  key    = each.value
  source = "./${each.value}"# its mean it depended on zip
  etag = filemd5( "./${each.value}")
  depends_on = [
   aws_s3_bucket.src,
      ]
}
resource "aws_iam_role" "ec2" {
  name = "test_role"

  assume_role_policy ="${file("assumerolepolicy.json")}"

  tags = {
    tag-key = "tag-value"
  }
}
resource "aws_iam_instance_profile" "profile1" {                   
            name  = "profile1"                         
role = "${aws_iam_role.ec2.name}"
}
resource "aws_iam_policy_attachment" "ec2-attach" {
  name       = "ec2-attachment"
  roles      = ["${aws_iam_role.ec2.name}"]
  policy_arn = "${aws_iam_policy.policy.arn}"
}
resource "aws_iam_policy" "policy" {
  name        = "ec2-policy"
  description = "A ec2 policy"
  policy      = "${file("policys3bucket.json")}"
}
resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.nginx.id
}

resource "aws_internet_gateway" "nginx" {
  vpc_id = aws_vpc.cowsay.id

  tags = {
    Name = "nginx"
  }
}
resource "aws_security_group" "cowsay" {
  name        = "cowsay"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.cowsay.id

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
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
    nat_gateway_id = aws_nat_gateway.gw.id
  }
  }
resource "aws_route_table" "nginx" {
  vpc_id = aws_vpc.cowsay.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nginx.id
    
  }
  tags = {
    Name = "cowsay"
  }
}
resource "aws_route_table_association" "nginx" {
  subnet_id  = aws_subnet.nginx.id
  route_table_id = aws_route_table.nginx.id

}

resource "aws_route_table_association" "cowsay" {
  subnet_id  = aws_subnet.cowsay_private.id
  route_table_id = aws_route_table.cowsay.id

}
resource "aws_instance" "cowsay" {
  ami = "ami-0502e817a62226e03"
 instance_type = "t2.micro"
#  associate_public_ip_address = true
 subnet_id  = aws_subnet.cowsay_private.id
 security_groups = ["${aws_security_group.cowsay.id}"]
iam_instance_profile = "${aws_iam_instance_profile.profile1.name}"
 key_name = "key"
 tags = {
    Name = "cowsay"
    }

user_data = "${file("npm_installation.sh")}"
   
}

resource "aws_instance" "nginx-instance" {
  ami = "ami-005b8739bcc8cf104"
  instance_type = "t2.micro"
  subnet_id  = aws_subnet.nginx.id
  associate_public_ip_address = true
  security_groups = ["${aws_security_group.cowsay.id}"]
  key_name = "key"
  tags = {
     Name = "nginx"
     }
  

 connection {
     type     = "ssh"
     user     = "bitnami"
     private_key = file("./key.pem")
     host     = aws_instance.nginx-instance.public_ip
   }

provisioner "file" {
     source      = "./key.pem"
     destination = "/tmp/key.pem"
   }

 provisioner "file" {
     source      = "./to-replace"
     destination = "/tmp/to-replace"
   }
 provisioner "file" {
     source      = "./nginx.conf"
     destination = "/tmp/nginx.conf"
   }


   provisioner "file" {
     source      = "./nginx.sh"
     destination = "/tmp/nginx.sh"
   }
    provisioner "remote-exec" {
     inline = [
         "sudo chmod 777 /tmp/to-replace",
     "echo ${aws_instance.cowsay.private_ip} > /tmp/to-replace",
      "sudo chmod 777 /tmp/nginx.conf",   
   "sudo chmod +x /tmp/nginx.sh",
   "sudo /tmp/nginx.sh",
     ]
  }
    
   depends_on = [
   aws_instance.cowsay,
      ]
   }
 output "nginx_ip" {
   description = "The public ip for ssh access"
value       = "${aws_instance.nginx-instance.public_ip}"
 }

output "instance_ip" {
  description = "The public ip for ssh access"
  value       = "${aws_instance.cowsay.private_ip}"
  
}
