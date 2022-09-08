#!/bin/bash
set -e

# Wrapper around terraform.  It is not possible to simply change the image name.
# Instead there are two instance_templates and the one currently not in use can be changed 
# and then assigned to the instance_group.
# TF_VAR_image_name is in the environment

terraform init
terraform fmt
if current_json="$(terraform output -json current 2>/dev/null)"; then
  current=$(jq -r '.current' <<< "$current_json")
  next=$(jq -r '.next' <<< "$current_json")
  image_name_current=$(jq -r '.image_name_current' <<< "$current_json")
  if [ $next = 0 ]; then
    export TF_VAR_image_name_0=$TF_VAR_image_name
    export TF_VAR_image_name_1=$image_name_current
  else
    export TF_VAR_image_name_1=$TF_VAR_image_name
    export TF_VAR_image_name_0=$image_name_current
  fi
  export TF_VAR_current=$next
else
  export TF_VAR_current=0
  export TF_VAR_image_name_0=$TF_VAR_image_name
  export TF_VAR_image_name_1=$TF_VAR_image_name
fi
terraform apply -auto-approve
