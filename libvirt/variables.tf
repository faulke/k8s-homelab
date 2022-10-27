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
    vcpu         = number
    memory       = number
    hostname     = string
    internal_ip  = string
    private_key  = string
    volumes      = list(any)
    k8s_master   = optional(bool, false)
    gitlab_agent = optional(string, "")
  }))
}
