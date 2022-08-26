all: image production

# 1a VPC
vpc:
	source ./local.env; cd image_tf; terraform init; terraform apply -auto-approve

# 1b Image via packer
image:
	source ./sourceenv.sh; env | grep PKR_VAR_; packer init .; packer build -machine-readable .

# 2 production using image
production:
	source ./sourceenv.sh; env | grep TF_VAR_; cd production_tf; terraform init; terraform fmt; terraform apply -auto-approve
