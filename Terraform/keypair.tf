resource "aws_key_pair" "vm" {
  key_name   = "vm-lab-key"
  public_key = file(pathexpand("~/.ssh/id_ed25519.pub"))
}