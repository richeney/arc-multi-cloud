#cloud-config
package_upgrade: true
packages:
- tree
- jq
users:
  - default
  - name: ${myadminuser}
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - ${mysshkey}