# ibm packer test
Create an image using packer.  Quick test of the image (optional).  Deploy image to production autoscale.

# Do it
Create your local.env file
```
cp template.local.env local.env
vi local.env
make
```

The make script will perform the following steps:
1. vpc - Create a new subnet for use by packer (creates a new  VPC as well)
1. image - Exeuctes packer to create a new image
1. test - Deploys the new image on an instance to a test VPC, you can ssh into the instance and look around
1. prod - Deploys the new image onto production vpc in an instance group

# make vpc
Invoke terraform in the image_tf directory to create a vpc and subnet for packer

# make image
Packer to create an image.  The image is recorded in packer-manifest.json see packer docs for details.

# make test
Invoke terraform in the test_tf directory to create a vpc, subnet and instance with the image just created in `make image`

# make prod
The production make target has two steps executed in the vpc_autoscale_tf directory:
- apply.sh
- roll.sh

apply.sh is required to manage the two instance_templates that must be managed for live deployment of the new image.  It is a wrapper around terraform.

roll.sh the instance_template is initialized with the new image so the new instances created will be correct.  The roll.sh script will delete the members of the image_group - one every 30 seconds.  This should be long enough to replace it before deleting the next one.  I use the following script in a different terminal session to watch it change over:

```
load_balancer=$(terraform output -state vpc_autoscale_tf/terraform.tfstate -raw load_balancer_hostname)
while sleep 1; do curl $load_balancer; done
```