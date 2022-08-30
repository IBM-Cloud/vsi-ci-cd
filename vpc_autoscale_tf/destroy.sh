#!/bin/bash
set -e
terraform init
terraform fmt
export TF_VAR_current=0
export TF_VAR_image_name_0="ibm-ubuntu-22-04-minimal-amd64-1"
export TF_VAR_image_name_1="$TF_VAR_image_name_0"
terraform destroy -auto-approve
