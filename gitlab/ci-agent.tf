data "gitlab_project" "homelab" {
  id = var.repo_path
}

resource "gitlab_cluster_agent" "agent" {
  project = data.gitlab_project.homelab.id
  name    = "homelab-agent-${var.env_name}"
}

resource "gitlab_cluster_agent_token" "agent_token" {
  project     = data.gitlab_project.homelab.id
  agent_id    = gitlab_cluster_agent.agent.agent_id
  name        = "token"
  description = "token for homelab agent"
}
