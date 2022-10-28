output "agent_token" {
  value     = gitlab_cluster_agent_token.agent_token.token
  sensitive = true
}
