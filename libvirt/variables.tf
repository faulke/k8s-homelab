variable env_name {
  type        = string
  description = "environment to deploy"
  default     = "dev"
}

variable network_id {
  type        = string
  description = "id for libvirt network"
}

variable bridge_network_name {
  type        = string
  description = "name of network bridge to host"
  default     = "br0"
}

variable pool_name {
  type        = string
  description = "name of pool for os volumes"
}

variable vms {
  type = list(object({
    name         = string
    os_volume_id = string
    disk_size    = number
    vcpu         = optional(number, 2)
    memory       = optional(number, 2048)
    hostname     = string
    internal_ip  = string
    private_key  = string
    volumes      = optional(list(any), [])
    k8s_master   = optional(bool, false)
    gitlab_agent = optional(string, "")
    taints       = optional(map(any), {})
    labels       = optional(map(any), {})
    bridge       = optional(string, "br0")
    disk_ids     = optional(list(string), [])
    cloud_init   = optional(string, "default-init.tpl")
  }))
}
