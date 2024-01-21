# create volume for each vm
resource "libvirt_volume" "this_vm_os" {
  for_each       = local.vms_map
  name           = "${each.value.name}.qcow2"
  size           = each.value.disk_size
  base_volume_id = each.value.os_volume_id
  pool           = var.pool_name
}

data "template_file" "cloud_init" {
  for_each = local.vms_map
  template = file("${path.module}/templates/${each.value.cloud_init}")

  vars = {
    hostname = each.value.name
  }
}

# create cloudinit disk to set hostname
resource "libvirt_cloudinit_disk" "this" {
  depends_on = [libvirt_volume.this_vm_os]
  for_each   = local.vms_map
  name       = "${each.value.name}-init.iso"
  user_data  = data.template_file.cloud_init[each.key].rendered
  pool       = var.pool_name
}

resource "libvirt_domain" "this" {
  depends_on  = [libvirt_cloudinit_disk.this]
  for_each    = local.vms_map
  name        = each.key
  vcpu        = each.value.vcpu
  memory      = each.value.memory
  qemu_agent  = true
  cloudinit   = libvirt_cloudinit_disk.this[each.key].id

  disk {
    volume_id = libvirt_volume.this_vm_os[each.value.name].id
  }

  dynamic "disk" {
    for_each = each.value.disk_ids
    content {
      volume_id = disk.value
    }
  }

  graphics {
    type           = "spice"
    listen_type    = "address"
    listen_address = "0.0.0.0"
  }

  # local
  network_interface {
    hostname       = each.value.hostname
    network_id     = var.network_id
    addresses      = [each.value.internal_ip]
    wait_for_lease = true
  }

  # bridge
  network_interface {
    hostname       = each.value.hostname
    bridge         = each.value.bridge
    wait_for_lease = true
  }
}

resource "null_resource" "master_deps" {
  depends_on = [libvirt_domain.this]

  for_each   = { for k in local.vms_map : k.internal_ip => k if k.k8s_master == true }

  connection {
    host        = each.key
    user        = "ubuntu"
    private_key = each.value.private_key
    timeout     = "60s"
  }

  provisioner "remote-exec" {
    inline = [
      "wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.25.0/kubeseal-0.25.0-linux-amd64.tar.gz",
      "tar -xvzf kubeseal-0.25.0-linux-amd64.tar.gz kubeseal",
      "sudo install -m 755 kubeseal /usr/local/bin/kubeseal"
    ]
  }
}
