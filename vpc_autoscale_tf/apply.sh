#!/bin/bash
set -e

# Expect the following variable name to be set
# TF_VAR_image_name=packer-20220829203907

terraform init
terraform fmt
if current_json="$(terraform output -json current)"; then
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
