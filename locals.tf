locals {
  k8s_network_name = "k8s-net-${var.env_name}"
  private_key      = file("${path.module}/tf-packer")
}