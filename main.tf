terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.6.14"
    }
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 3.18.0"
    }
  }
}

variable provider_uri {
  type        = string
  description = "qemu uri for vm host"
  default     = "qemu:///system"
}

variable env_name {
  type        = string
  description = "environment to deploy"
  default     = "dev"
}

variable network_cidr {
  type    = string
  default = "10.0.0.0/24"
}

variable master_internal_ip {
  type    = string
  default = "10.0.0.6"
}

variable worker_internal_ip {
  type    = string
  default = "10.0.0.10"
}

variable pods_cidr {
  default = "10.42.0.0/16"
}

variable services_cidr {
  default = "10.43.0.0/16"
}

variable base_image_source {
  type        = string
  description = "source path for os image from packer"
  default     = "./packer/build/ubuntu"
}

variable pool {
  type = object({
    name = string
    path = string
  })
  default = {
    name = "main"
    path = "/home/evan/pool"
  }
}

variable gitlab_access_token {
  type        = string
  description = "gitlab token for access to homelab repo"
  sensitive   = true
}

variable gitlab_repo_path {
  type        = string
  description = "gitlab repo path with agent"
  default     = "faulke/homelab"
}

locals {
  k8s_network_name = "k8s-net-${var.env_name}"
}

### GITLAB AGENT RESOURCES - MUST APPLY FIRST
provider "gitlab" {
  token = var.gitlab_access_token
}

module "gitlab" {
  source = "./gitlab"

  access_token = var.gitlab_access_token
  repo_path    = var.gitlab_repo_path
  env_name     = var.env_name
}

### BASE LIBVIRT RESOURCES

provider "libvirt" {
  uri   = var.libvirt_provider_uri
  alias = "main"
}

# create network
resource "libvirt_network" "k8s_local" {
  name      = local.k8s_network_name
  addresses = [var.network_cidr]
  autostart = true
}

# create image pool
resource "libvirt_pool" "main" {
  name = var.pool.name
  type = "dir"
  path = var.pool.path
}

# create main os volume
resource "libvirt_volume" "ubuntu" {
  name     = "ubuntu.qcow2"
  source   = var.base_image_source
  pool     = libvirt_pool.main.name
}

### VMS

# homelab vms
module "homelab_libvirt" {
  source     = "./libvirt"
  network_id = libvirt_network.k8s_local.id
  pool_name  = libvirt_pool.main.name

  vms = [
    {
      name         = "homelab-master-${var.env_name}"
      os_volume_id = libvirt_volume.ubuntu.id
      disk_size    = 15032385536 # 14G in bytes
      vcpu         = 2
      memory       = 2048
      hostname     = "homelab-master-${var.env_name}"
      internal_ip  = var.master_internal_ip
      private_key  = file("${path.module}/tf-packer")
      k8s_master   = true
      gitlab_agent = module.gitlab.agent_token

      volumes  = [] # additional volumes
    },
    {
      name         = "homelab-worker-${var.env_name}"
      os_volume_id = libvirt_volume.ubuntu.id
      disk_size    = 15032385536 # 14G in bytes
      vcpu         = 2
      memory       = 2048
      hostname     = "homelab-worker-${var.env_name}"
      internal_ip  = var.worker_internal_ip
      private_key  = file("${path.module}/tf-packer")

      volumes  = [] # additional volumes
    }
  ]
}

### CLUSTERS

# homelab cluster
module "homelab_cluster" {
  depends_on = [module.homelab_libvirt]
  source     = "./k3s"

  cluster_domain = "homelab.${var.env_name}"
  pods_cidr      = var.pods_cidr
  services_cidr  = var.services_cidr
  master_nodes   = module.homelab_libvirt.k8s_master_nodes
  agent_nodes    = module.homelab_libvirt.k8s_agent_nodes
}
