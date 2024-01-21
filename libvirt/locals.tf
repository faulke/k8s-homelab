locals {
  vms_map = { for vm in var.vms: vm.name => vm }
}
