# Busca a imagem Ubuntu 24.04 mais recente
data "aws_ami" "ubuntu_west2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Busca Ubuntu em us-west-1
data "aws_ami" "ubuntu_west1" {
  provider    = aws.west
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical

}


# EC2 em us-west-2
resource "aws_instance" "ubuntu_west2" {
  ami           = data.aws_ami.ubuntu_west2.id
  instance_type = var.instance_type

  tags = {
    Name = "terraform-ubuntu"
  }
}

# EC2 em us-west-1    
resource "aws_instance" "ubuntu_west1" {
  provider = aws.west

  ami           = data.aws_ami.ubuntu_west1.id
  instance_type = var.instance_type

  tags = {
    Name = "terraform-ubuntu"
  }
}



output "instance_id_west2" {
  value = aws_instance.ubuntu_west2.id
}

output "public_ip" {
  value = aws_instance.ubuntu_west2.public_ip
}



output "instance_id_west1" {
  value = aws_instance.ubuntu_west1.id
}

output "public_ip_west1" {
  value = aws_instance.ubuntu_west1.public_ip
}