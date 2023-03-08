packer {
  required_version = "~> 1.8.2"

  required_plugins {
    qemu = {
      version = ">= 1.0.4"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "example" {
  iso_url                = "https://releases.ubuntu.com/jammy/ubuntu-22.04.2-live-server-amd64.iso"
  iso_checksum           = "sha256:5e38b55d57d94ff029719342357325ed3bda38fa80054f9330dc789cd2d43931"
  output_directory       = "build"
  shutdown_command       = "echo 'packer' | sudo -S shutdown -P now"
  disk_size              = "4096M"
  disk_image             = false
  memory                 = "1024"
  format                 = "qcow2"
  accelerator            = "kvm"
  http_directory         = "http"
  ssh_username           = "ubuntu"
  ssh_password           = "ubuntu"
  ssh_timeout            = "20m"
  ssh_handshake_attempts = 1000
  vm_name                = "ubuntu"
  net_device             = "virtio-net"
  disk_interface         = "virtio"
  boot_wait              = "10s"
  headless               = true
  qemuargs = [
    ["-net", "nic,model=virtio"]
  ]
  boot_command = [
    "c",
    "linux /casper/vmlinuz --- autoinstall ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/' ",
    "<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]
}

build {
  sources = ["source.qemu.example"]

  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done"
    ]
  }

  provisioner "file" {
    source      = "../tf-packer.pub"
    destination = "/tmp/tf-packer.pub"
  }

  provisioner "shell" {
    script = "./scripts/setup.sh"
    execute_command = "chmod +x '{{.Path}}'; {{.Vars}} sudo -S -E bash '{{.Path}}';"
  }
}
