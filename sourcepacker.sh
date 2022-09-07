# source this file to initialize the PKR_VAR_ variables required for packer
source ./local.env
echo "$(terraform output -state=image_tf/terraform.tfstate -raw packer)"
eval "$(terraform output -state=image_tf/terraform.tfstate -raw packer)"