output "kube_config" {
  value     = module.k3s.kube_config
  sensitive = true
}

output "cluster_domain" {
  value = var.cluster_domain
}