locals {
  vms_map = { for vm in var.vms: vm.name => vm }
  gitlab_agents = [ for vm in var.vms : vm if vm.gitlab_agent != "" ]
}
