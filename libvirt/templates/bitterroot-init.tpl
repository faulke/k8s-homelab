#cloud-config
hostname: ${hostname}
fs_setup:
  - label: data
    device: /dev/vdb
    filesystem: ext4
    partition: auto
mounts:
  - [ vdb, /data, "auto", "rw,user,exec,nofail", "0", "0" ]
runcmd:
  - [ mkdir, -p, /data/sonarr ]
  - [ chmod, -R, 777, /data ]