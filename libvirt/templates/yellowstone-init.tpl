#cloud-config
hostname: ${hostname}
fs_setup:
  - label: config
    device: /dev/vdb
    filesystem: ext4
    partition: auto
mounts:
  - [ vdb, /config, "auto", "rw,user,exec,nofail", "0", "0" ]
runcmd:
  - [ chmod, -R, 777, /config ]