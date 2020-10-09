#!/bin/bash

if [[ -z "$(terraform output azure_public_ip)" ]] 
then
  echo "Refreshing Terraform state...."
  terraform refresh
fi

tee ./hosts <<EOF  
$(terraform output azure_public_ip)

[arc]
$(terraform output aws_public_ip)
$(terraform output gcp_public_ip)
EOF

exit 0
