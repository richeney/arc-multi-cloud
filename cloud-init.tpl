#cloud-config
manage_etc_hosts: true
hostname: ${hostname}
users:
  - default
  - name: ${myadminuser}
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - ${mysshkey}
