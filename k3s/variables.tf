variable cluster_domain {
  type        = string
  description = "domain name for kubernetes cluster"
}

variable pods_cidr {
  type        = string
  description = "cidr block for pods"
}

variable services_cidr {
  type        = string
  description = "cidr block for services"
}

variable master_nodes {
  type        = map(any)
  description = "map of master nodes"
}

variable agent_nodes {
  type        = map(any)
  description = "map of agent nodes"
}