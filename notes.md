1. Install terraform and packer
2. Create ssh keypair: ssh-keygen -t rsa -C "<email>" -f <key_name>
3. Add user to libvirt, kvm, libvirt-qemu groups

# Dedicated NIC for plex
1. Create a new worker node dedicated for Plex
2. Use taints and tolerations/nodeSelector to make sure plex is deployed to this node:
https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
3. Only if necessary... might not need dedicated NIC