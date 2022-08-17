# source this file to get all the environment variables set
source local.env
echo "$(terraform output -state=tf/terraform.tfstate -raw packer)"
eval "$(terraform output -state=tf/terraform.tfstate -raw packer)"
env | grep PKR_VAR_
