output "vpc_id" {
    value = data.aws_vpc.default.id
}

output "public_ip" {
    value = aws_instance.vm.public_ip
}

output "ssh" {
    value = "ssh -i ssh-key/vm-lab ubuntu@{aws_instance.vm.public_ip}"
}