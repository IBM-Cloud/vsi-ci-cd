# vsi-ci-cd
Create an image using packer.  Demonstrate the roll out in two different environments:
1. simple - vpc with one instance
2. autoscale - instance group with autoscale configuration

Companion repository to the blog post: URL

![image](https://user-images.githubusercontent.com/6932057/188900788-18736f50-1ffe-4975-929e-cdd5df2b389c.png)


# Create the resources

## Prerequisites 
Permissions to create resources, including VPC, instances, etc.
- VPC SSH key
- Use the [IBM Cloud Shell](https://cloud.ibm.com/shell) or make sure you have [Shell with ibmcloud cli, terraform, jq and git](https://cloud.ibm.com/docs/solution-tutorials?topic=solution-tutorials-tutorials)

[Packer](https://www.packer.io/downloads) must be installed. In the IBM Cloud Shell you can do the following:
```
wget https://releases.hashicorp.com/packer/1.8.3/packer_1.8.3_linux_amd64.zip
unzip packer_1.8.3_linux_amd64.zip
PATH=`pwd`:$PATH
```

## Configure and create

Get the source and edit the local.env file
```
git clone https://github.com/IBM-Cloud/vsi-ci-cd
cd vsi-ci-cd
cp template.local.env local.env
```

Use your editor to make the changes described in the comments:
```
edit local.env
```

Terraform 1.2.8 or better is required.  The tfswitch tool will update if installed (it is available on IBM Cloud Shell).  If you do not have this install terraform:
```
(cd image_tf && tfswitch)
```

Build image, deploy to simple and autoscale.
```
make
```

See `make clean` below to remove up all the resources.

## Test via curl
Find the public ip address of the simple instance and curl:
```
public_ip=$(terraform output -state simple_tf/terraform.tfstate -raw public_ip)
echo $public_ip
while sleep 1; do curl $public_ip; done
```

Find the public DNS name of the load balancer and curl:
```
load_balancer=$(terraform output -state vpc_autoscale_tf/terraform.tfstate -raw load_balancer_hostname)
echo $load_balancer
while sleep 1; do curl $load_balancer; done
```

The make targets can also be used:
```
make simple_curl
make autoscale_curl
```

# make
The default make target executed above is **all** and it perform the following steps:
1. vpc - Create a new subnet for use by packer (creates a new  VPC as well)
1. image - Exeuctes packer to create a new image
1. simple - Deploys the new image on an instance to a simple VPC, you can ssh into the instance and look around
1. autoscale - Deploys the new image onto production vpc in an instance group

The next sections describe each target

# make vpc
Invoke terraform in the image_tf directory to create a vpc and subnet for packer.  The `terraform output` captures the packer variables.

# make image
Packer to create an image.  The image is recorded in packer-manifest.json see packer docs for details. This is **Image Pipeline** in the diagram.

# make tag
Delete the tag from all images and then add the tag to the latest packer image.  The file packer-manifest.json will be used to identify the latest image.

# make simple
Invoke terraform in the simple_tf directory to create a vpc, subnet and instance with the image just tagged in `make tag`.

# make autoscale
![image](https://user-images.githubusercontent.com/6932057/188898113-6c9743ce-0590-407c-bc8d-6b16fdf699a3.png)

The autoscale production make target has two steps executed in the vpc_autoscale_tf directory:
- apply.sh
- roll.sh

**apply.sh** is required to manage the two instance_templates that must be managed for live deployment of the new image.  It is a wrapper around terraform.

**roll.sh** - After the instance_template is initialized with the new image the new instances created will be rolled out.  The roll.sh script will delete the members of the image_group - one every 30 seconds.  This should be long enough to replace it before deleting the next one.

# make rollout
Steps:
- make image
- make simple
- make prod

This will create a new image and provision.  Use the **Test via curl** scripts above in a different terminal sessions to watch it change over.  You can transfer the public_ip and load_balancer shell variables to your desktop.

# make clean
Clean up all of the resources.