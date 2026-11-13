data "proxmox_virtual_environment_vms" "template" {

  filter {
    name   = "template"
    values = [true]
  }
}

locals {
  templates = { for vm in data.proxmox_virtual_environment_vms.template.vms : vm.node_name => vm.vm_id }
}


output "id-template" {
  value = local.templates
}

