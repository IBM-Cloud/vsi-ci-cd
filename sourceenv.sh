# source this file to get all the environment variables set
source local.env
cd tf
echo $(terraform output -raw packer)
eval $(terraform output -raw packer)
cd ..
env | grep PKR_VAR_
