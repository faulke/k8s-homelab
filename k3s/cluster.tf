module "k3s" {
  source         = "xunleii/k3s/module"
  use_sudo       = true
  k3s_version    = "v1.25.3+k3s1"
  cluster_domain = var.cluster_domain
  managed_fields = ["label", "taint"]

  cidr = {
    pods     = var.pods_cidr
    services = var.services_cidr
  }

  drain_timeout = "60s"

  servers = {
    for node in var.master_nodes:
      node.name => {
        ip = node.internal_ip

        connection = {
          host        = node.internal_ip
          user        = "ubuntu"
          private_key = node.private_key
          timeout     = "10s"
        }

        labels = {
          "node.kubernetes.io/type" = "master"
          "svccontroller.k3s.cattle.io/enablelb" = "true" # lb only on master for now
        }

        # taints = {
        #   "node.k3s.io/type" = "server:NoSchedule"
        # }

        flags = [
          "--disable traefik"
        ]
      }
  }

  agents = {
    for node in var.agent_nodes:
    node.name => {
      ip = node.internal_ip

      connection = {
        host        = node.internal_ip
        user        = "ubuntu"
        private_key = node.private_key
        timeout     = "10s"
      }

      labels = node.labels
      taints = node.taints
    }
  }
}
