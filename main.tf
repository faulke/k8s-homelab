terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.6"
    }
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = ">=16.8.0"
    }
    flux = {
      source = "fluxcd/flux"
      version = "1.2.2"
    }
  }
}

### GITLAB AGENT RESOURCES - MUST APPLY FIRST
provider "gitlab" {
  token = var.gitlab_token
}

module "gitlab" {
  source = "./gitlab"

  group        = var.gitlab_group
  project      = var.gitlab_project
  env_name     = var.env_name
}

### BASE LIBVIRT RESOURCES

provider "libvirt" {
  uri   = var.libvirt_provider_uri
  alias = "main"
}

# create vm network
resource "libvirt_network" "k8s_local" {
  name      = local.k8s_network_name
  addresses = [var.network_cidr]
  autostart = true
}

# create two bridge networks
resource "libvirt_network" "main" {
  name      = var.main_net_bridge
  mode      = "bridge"
  bridge    = var.main_net_bridge
  autostart = true
}

resource "libvirt_network" "dedicated" {
  name      = var.dedicated_net_bridge
  mode      = "bridge"
  bridge    = var.dedicated_net_bridge
  autostart = true
}

# create main os volume
resource "libvirt_volume" "ubuntu" {
  name     = "ubuntu.qcow2"
  source   = var.base_image_source
  pool     = var.pool.name
}

# yellowstone node config volume
resource "libvirt_volume" "yellowstone" {
  name     = "yellowstone_config.qcow2"
  size     = var.yellowstone.config_volume_size
  pool     = var.pool.name
}

# bitterroot node extra volume
resource "libvirt_volume" "bitterroot" {
  name     = "bitterroot-data.qcow2"
  size     = var.bitterroot.data_volume_size
  pool     = var.pool.name
}

### VMS

# homelab vms
module "homelab_libvirt" {
  source     = "./libvirt"
  network_id = libvirt_network.k8s_local.id
  pool_name  = var.pool.name

  vms = [
    {
      name         = "homelab-master-${var.env_name}"
      os_volume_id = libvirt_volume.ubuntu.id
      disk_size    = var.master.volume_size
      hostname     = "master-${var.env_name}"
      internal_ip  = var.master.internal_ip
      private_key  = local.private_key
      k8s_master   = true
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
      bridge       = libvirt_network.dedicated.name # dedicated nic on host
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


resource "local_file" "kube_config" {
  content  = module.homelab_cluster.kube_config
  filename = "${path.module}/kube_config"
}


### FLUX
provider "flux" {
  kubernetes = {
    config_path = local_file.kube_config.filename
  }
  git = {
    url = "ssh://git@gitlab.com/${module.gitlab.project_path}.git"
    ssh = {
      username    = "git"
      private_key = module.gitlab.private_key_pem
    }
  }
}

resource "flux_bootstrap_git" "this" {
  depends_on = [module.gitlab.deploy_key]

  path           = "clusters/${var.env_name}"
  cluster_domain = module.homelab_cluster.cluster_domain
}

