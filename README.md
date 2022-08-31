# vsi-ci-cd
Create an image using packer.  Quick test of the image (optional).  Deploy image to production autoscale.

Companion repository to the blog post: URL

![image](https://user-images.githubusercontent.com/6932057/187541652-c3bb54b6-6471-44e5-a27a-2250e2c1f35a.png)


# Create the resources

## Prerequisites 
Permissions to create resources, including VPC and instances, Transit Gateway, etc.
- VPC SSH key
- [Shell with ibmcloud cli, terraform, jq and git](https://cloud.ibm.com/docs/solution-tutorials?topic=solution-tutorials-tutorials)

Create your local.env file
```
cp template.local.env local.env
edit local.env
make
```

Use the following script to see the load balancer work:

```
load_balancer=$(terraform output -state vpc_autoscale_tf/terraform.tfstate -raw load_balancer_hostname)
while sleep 1; do curl $load_balancer; done
```

The make script will perform the following steps:
1. vpc - Create a new subnet for use by packer (creates a new  VPC as well)
1. image - Exeuctes packer to create a new image
1. test - Deploys the new image on an instance to a test VPC, you can ssh into the instance and look around
1. prod - Deploys the new image onto production vpc in an instance group


# make vpc
Invoke terraform in the image_tf directory to create a vpc and subnet for packer

# make image
Packer to create an image.  The image is recorded in packer-manifest.json see packer docs for details. This is **step 1** in the diagram.

# make test
Invoke terraform in the test_tf directory to create a vpc, subnet and instance with the image just created in `make image`

# make prod
The production make target has two steps executed in the vpc_autoscale_tf directory:
- apply.sh
- roll.sh
This is **step 2** in the diagram.

**apply.sh** is required to manage the two instance_templates that must be managed for live deployment of the new image.  It is a wrapper around terraform.

**roll.sh** - After the instance_template is initialized with the new image the new instances created will be rolled out.  The roll.sh script will delete the members of the image_group - one every 30 seconds.  This should be long enough to replace it before deleting the next one.

# make rollout

Two steps:
- make image
- make prod

This will create a new image and provision it without iterruption.  Use the following script in a different terminal session to watch it change over:


```
load_balancer=$(terraform output -state vpc_autoscale_tf/terraform.tfstate -raw load_balancer_hostname)
while sleep 1; do curl $load_balancer; done
```


# make clean
Clean up all of the resources