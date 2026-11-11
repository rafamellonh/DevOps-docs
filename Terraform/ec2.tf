data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "vm" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t3.micro"
    key_name = aws_key_pair.vm.key_name
    vpc_security_group_ids = [aws_security_group.vm01.id]

    tags = {
      name = "vm-lab-01"
    }
}