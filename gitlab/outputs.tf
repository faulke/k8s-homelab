output "deploy_key" {
  value     = gitlab_deploy_key.flux
  sensitive = true
}

output "project_path" {
  value = data.gitlab_project.flux.path_with_namespace
}

output "private_key_pem" {
  value     = tls_private_key.flux.private_key_pem
  sensitive = true
}
