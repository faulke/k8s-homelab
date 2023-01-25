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

# yellowstone node config volume
resource "libvirt_volume" "yellowstone" {
  name     = "yellowstone_config.qcow2"
  size     = var.yellowstone.config_volume_size
  pool     = libvirt_pool.main.name
}

# bitterroot node extra volume
resource "libvirt_volume" "bitterroot" {
  name     = "bitterroot-data.qcow2"
  size     = var.bitterroot.data_volume_size
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
      disk_size    = var.master.volume_size
      hostname     = "master-${var.env_name}"
      internal_ip  = var.master.internal_ip
      private_key  = local.private_key
      k8s_master   = true
      gitlab_agent = module.gitlab.agent_token
    },
    {
      name         = "homelab-worker-bitterroot-${var.env_name}"
      os_volume_id = libvirt_volume.ubuntu.id
      disk_size    = var.bitterroot.volume_size
      hostname     = "bitterroot-${var.env_name}"
      internal_ip  = var.bitterroot.internal_ip
      private_key  = local.private_key
      disk_ids     = [libvirt_volume.bitterroot.id]
      cloud_init   = "bitterroot-init.tpl"
      taints       = {
        "dedicated" = "bitterroot:NoSchedule"
      }
      labels       = {
        "dedicated" = "bitterroot"
      }
    },
    {
      name         = "homelab-worker-yellowstone-${var.env_name}"
      os_volume_id = libvirt_volume.ubuntu.id
      disk_size    = var.yellowstone.volume_size
      hostname     = "yellowstone-${var.env_name}"
      internal_ip  = var.yellowstone.internal_ip
      private_key  = local.private_key
      bridge       = "br1" # dedicated nic on host
      disk_ids     = [libvirt_volume.yellowstone.id] # additional disks to mount
      cloud_init   = "yellowstone-init.tpl"
      taints       = {
        "dedicated" = "yellowstone:NoSchedule"
      }
      labels       = {
        "dedicated" = "yellowstone"
      }
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
