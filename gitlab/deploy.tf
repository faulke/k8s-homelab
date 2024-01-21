resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

data "gitlab_project" "flux" {
  path_with_namespace = "${var.group}/${var.project}"
}

resource "gitlab_deploy_key" "flux" {
  project  = data.gitlab_project.flux.id
  title    = "flux-deploykey-${var.env_name}"
  key      = tls_private_key.flux.public_key_openssh
  can_push = true
}
