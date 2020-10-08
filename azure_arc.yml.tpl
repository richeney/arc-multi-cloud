---
# Note that this template is not currently in use
# Ansible Playbook to add agent and onboard to Azure Arc
# See https://github/com/richeney/arc
# Run using remote-exec, e.g.:
# ansible-playbook -i <IP Address>, --private-key <private key path> ./azure_arc.yml
#  Don't forget the comma after the IP address tso that it is interpreted as a list

- hosts: all
  become: yes
  tasks:
  - name: Download the 16.04 packages file
    get_url:
      url: https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb
      dest: /tmp/packages-microsoft-prod.deb
      mode: '0444'
    when: ansible_distribution == 'Ubuntu' and ansible_distribution_version == '16.04'
  - name: Download the 18.04 packages file
    get_url:
      url: https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
      dest: /tmp/packages-microsoft-prod.deb
      mode: '0444'
    when: ansible_distribution == 'Ubuntu' and ansible_distribution_version == '18.04'
  - name: Download the 20.04 packages file
    get_url:
      url: https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
      dest: /tmp/packages-microsoft-prod.deb
      mode: '0444'
    when: ansible_distribution == 'Ubuntu' and ansible_distribution_version == '20.04'
  - name: Install the .deb package
    apt:
      deb: /tmp/packages-microsoft-prod.deb
  - name: Pause 10 seconds
    pause:
      seconds: 10
  - name: Update apt list
    apt:
      update_cache: yes
  - name: Pause 10 seconds
    pause:
      seconds: 10
  - name: Install the azcmagent agent and a few other packages
    apt:
      name:
      - tree
      - jq
      - aptitude
      - azcmagent
      state: present
  - name: Pause 10 seconds
    pause:
      seconds: 10
  - name: Connect to Azure using azcmagent connect
    command:
      argv:
        - /usr/bin/azcmagent
        - connect
        - --tenant-id
        - ${tenant_id}
        - --service-principal-id
        - ${service_principal_appid}
        - --service-principal-secret
        - ${service_principal_secret}
        - --subscription-id
        - ${subscription_id}
        - --resource-group
        - ${resource_group}
        - --location
        - ${location}
        - --tags
        - cloud=${cloud},hostname=${hostname},managed_by=arc
...
