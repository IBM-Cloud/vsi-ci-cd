# make everything
all: vpc image tag simple autoscale

# make image then roll out to simple and autoscale
rollout: image tag simple autoscale

# clean everything but the images
clean: autoscale_clean simple_clean vpc_clean images_clean

# vpc for making an image with packer ---------------
vpc:
	source ./local.env; cd image_tf; terraform init; terraform fmt; terraform apply -auto-approve
vpc_clean:
	source ./local.env; cd image_tf; terraform init; terraform fmt; terraform destroy -auto-approve

# image pipeline with packer -----------------
image:
	source ./local.env; source ./sourcepacker.sh; packer init .; packer build -machine-readable .
tag:
	source ./local.env ; source ./sourceimage.sh; ./image-move-tag.sh
images_clean:
	source ./local.env; ./images-delete.sh

# simple deploy pipeline: instance in a vpc ------------------------
simple:
	source ./local.env; source ./sourceimage.sh; cd simple_tf; terraform init; terraform fmt; terraform apply -auto-approve
simple_clean:
	source ./local.env; source ./sourcepacker.sh; source ./sourceimage.sh; cd simple_tf; terraform init; terraform fmt; terraform destroy -auto-approve
simple_curl:
	public_ip=$$(terraform output -state simple_tf/terraform.tfstate -raw public_ip); while sleep 1; do curl $$public_ip; done

# autoscale deploy pipeline: roll out to an instance group in autoscale ---------------
autoscale: autoscale_apply autoscale_roll

# image name is that last image built by packer
autoscale_apply:
	source ./local.env; source ./sourceimage.sh; cd vpc_autoscale_tf; ./apply.sh
autoscale_roll:
	source ./local.env; cd vpc_autoscale_tf; ./roll.sh
autoscale_clean:
	source ./local.env; cd vpc_autoscale_tf; ./destroy.sh
autoscale_curl:
	load_balancer=$$(terraform output -state vpc_autoscale_tf/terraform.tfstate -raw load_balancer_hostname); while sleep 1; do curl $$load_balancer; done