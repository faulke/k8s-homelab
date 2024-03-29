variable libvirt_provider_uri {
  type        = string
  description = "qemu uri for libvirt host"
}

variable env_name {
  type        = string
  description = "environment to deploy"
  default     = "dev"
}

variable network_cidr {
  type        = string
  description = "cidr block for libvirt network"
}

variable main_net_bridge {
  type        = string
  description = "name of host bridge for most nodes"
}

variable dedicated_net_bridge {
  type        = string
  description = "name of host bridge for dedicated nodes"
}

variable master {
  type = object({
    internal_ip = string
    volume_size = optional(number, 15032385536)
  })
  description = "configuration for master node"
}

variable bitterroot {
  type = object({
    internal_ip = string
    volume_size = optional(number, 15032385536)
    data_volume_size = optional(number, 5368709120)
  })
  description = "configuration for bitterroot node"
}

variable yellowstone {
  type = object({
    internal_ip = string
    volume_size = optional(number, 15032385536)
    config_volume_size = optional(number, 5368709120)
  })
  description = "configuration for yellowstone node"
}

variable pods_cidr {
  type        = string
  description = "cidr block for k8s pods"
}

variable services_cidr {
  type        = string
  description = "cidr block for k8s services"
}

variable base_image_source {
  type        = string
  description = "source path for os image from packer"
}

variable pool {
  type = object({
    name = string
    path = string
  })
  description = "config for libvirt storage pool"
}

variable gitlab_token {
  type        = string
  description = "gitlab token for access to homelab repo"
  sensitive   = true
}

variable gitlab_group {
  type        = string
  description = "gitlab group path for homelab"
}

variable gitlab_project {
  type        = string
  description = "gitlab project path for homelab"
}
