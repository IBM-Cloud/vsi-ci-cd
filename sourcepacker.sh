#/bin/bash
# source this file
# initialize the PKR_VAR_ variables required for packer

echo "$(terraform output -state=image_tf/terraform.tfstate -raw packer)"
eval "$(terraform output -state=image_tf/terraform.tfstate -raw packer)"
