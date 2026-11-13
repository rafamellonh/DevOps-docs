resource "proxmox_virtual_environment_vm" "vm_ubuntu" {
  name        = "vm-ubuntu"
  description = "vm-template-terraform"
  tags        = ["terraform", "ubuntu"]
  node_name   = var.node_name
  vm_id       = 500

  clone {
    vm_id     = local.templates[var.node_name]
    node_name = var.node_name
    full      = true
  }

  agent {
    enabled = false
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 20
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "192.168.2.50/24"
        gateway = "192.168.2.1"
        
      }
    }
    user_account {
      username = "rafael"
      keys     = [trimspace(file("~/.ssh/id_ed25519.pub"))]
    }
  }
}