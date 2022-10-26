output "vms_map" {
  value = local.vms_map
}

output "k8s_master_nodes" {
  value = {for val in var.vms: val.name => val if val.k8s_master == true}
}

output "k8s_agent_nodes" {
  value = {for val in var.vms: val.name => val if val.k8s_master != true}
}
