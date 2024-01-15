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
- For prod: custom values in gitlab agent file - https://docs.gitlab.com/ee/user/clusters/agent/gitops/helm.html#custom-values

- secrets: https://github.com/bitnami-labs/sealed-secrets#usage
  - fetch cert: sudo kubeseal --kubeconfig=/etc/rancher/k3s/k3s.yaml --fetch-cert >secrets.pub
  - base64 encode secret
  - echo -n bar | sudo kubectl create secret generic mysecret --dry-run=client --from-file=foo=/dev/stdin -o yaml >mysecret.yaml
  - add base64 string in yaml data
  - install kubeseal on teton
  - kubeseal --cert secrets.pub <secret.yaml >sealedsecret.yaml
  - copy encrypted data string to secrets chart values.yaml

# Building VM host
- Create two network bridges with static IPs in netplan
- Create VM network bridges
  - br0
  - br1

# manual configuration
- virt-manager
  - set Display to VNC Server
- pihole
  - custom dns entries for each service, pointed at master node ip address
    - e.g., plex.homelab.com > 192.168.40.195
- qbittorrent
  - downloads = /data/torrents/complete & /data/torrents/incomplete
  - make sure Advanced > Network Interface = tun0
  - set seed limit to 30 min or so
  - set make upload speed and connections
  - admin:adminadmin is default
  - to check vpn status:
    - get shell in container: sudo kubectl exec --stdin --tty {pod name, e.g., homelab-dev-qbittorrent} /bin/bash
    - view connected status: cat /shared/vpnstatus   = connected/disconnected
- radarr & sonarr
  - add qbittorrent client
    - use homelab-dev-qbittorrent for host
    - port 8080
    - admin:adminadmin is default
  - add indexers from jackett.homelab.com
- plex
  - need to access from localhost to setup server
    - from optiplex: ssh -i ~/Downloads/tf-packer -L 8888:10.43.244.191:80 ubuntu@192.168.40.190
    - go to: 127.0.0.1:8888/web
    - currently "not authorized"
    - get into container and follow these instructions, then restart: https://support.plex.tv/articles/204281528-why-am-i-locked-out-of-server-settings-and-how-do-i-get-in/
  - last resort is yellowstone-worker is desktop version of ubuntu, use virt-manager display
  - 