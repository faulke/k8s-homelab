1. Install terraform and packer
2. Create ssh keypair: ssh-keygen -t rsa -C "<email>" -f <key_name>
3. Add user to libvirt, kvm, libvirt-qemu groups

# Dedicated NIC for plex
1. Create a new worker node dedicated for Plex
2. Use taints and tolerations/nodeSelector to make sure plex is deployed to this node:
https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
3. Only if necessary... might not need dedicated NIC

# Volumes for large storage on worker nodes
1. Plex node - 50G for config
2. qbittorrent/radarr/sonarr/jackett node - 200G for downloads

# Services
1. Jackett
2. Sonarr
3. Radarr
4. Qbittorrent + Open vpn sidecar (k8s-@-home)

# Manifests w/ helm and k3s
https://docs.k3s.io/helm

# Gitlab gitops for Kubernetes
https://docs.gitlab.com/ee/user/clusters/agent/gitops.html

# Helm charts in gitlab package registry
https://docs.gitlab.com/ee/user/packages/helm_repository/
- this won't work for Helm CRD, because it's a private repo

- Create own common app chart (deployment, service, ingress) like old library
- Use k8s-at-home library chart
- Create nfs pv chart

- Create new gitlab agent token for prod
- Use tag or prod branch in agent config

- How to deploy dev and prod clusters separately with unique values?
- chart-of-charts approach? dev default values, prod overwrite values.

- For dev: gitlab agent -> deploys on master
- For prod: ci/cd -> update deps -> helm install using gitlab agent context
https://docs.gitlab.com/ee/user/clusters/agent/ci_cd_workflow.html
- how to avoid checking 

- secrets: https://github.com/bitnami-labs/sealed-secrets#usage

# Building VM host
- Add two nics w/ static IPs
- Create VM network bridge
