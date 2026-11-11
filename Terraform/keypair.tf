resource "aws_key_pair" "vm" {
  key_name   = "vm-key-lab"
  public_key = file("${path.module}/ssh-key/vm-lab.pub")
}