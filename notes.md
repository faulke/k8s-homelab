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