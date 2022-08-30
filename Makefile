# make everything
all: vpc image test_tf prod

test: image test_tf

# make image then roll out to production
rollout: image prod

# clean everything but the images
clean: clean_prod clean_test clean_vpc

# vpc for making an image ---------------
vpc:
	source ./local.env; cd image_tf; terraform init; terraform apply -auto-approve

clean_vpc:
	source ./local.env; cd image_tf; terraform init; terraform destroy -auto-approve

# image with packer
image:
	source ./sourceenv.sh; env | grep PKR_VAR_; packer init .; packer build -machine-readable .

# test image, ssh to the image if you want to check it out
test:
	source ./sourceenv.sh; env | grep TF_VAR_; cd test_tf; terraform init; terraform fmt; terraform apply -auto-approve

clean_test:
	source ./sourceenv.sh; env | grep TF_VAR_; cd test_tf; terraform init; terraform fmt; terraform destroy -auto-approve

# roll out to an instance group in production ---------------
prod: prod_apply prod_roll

prod_apply:
	source ./sourceenv.sh; env | grep TF_VAR_; cd vpc_autoscale_tf; ./apply.sh

prod_roll:
	source ./sourceenv.sh; env | grep TF_VAR_; cd vpc_autoscale_tf; ./roll.sh

clean_prod:
	source ./sourceenv.sh; env | grep TF_VAR_; cd vpc_autoscale_tf; ./destroy.sh