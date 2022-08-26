# source this file to get all the environment variables set
source local.env
echo "$(terraform output -state=image_tf/terraform.tfstate -raw packer)"
eval "$(terraform output -state=image_tf/terraform.tfstate -raw packer)"
export TF_VAR_image_name=$(jq -r '.builds[-1].custom_data.image_name' packer-manifest.json)