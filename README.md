# vsi-ci-cd
This is a companion repository to the blog post: [Design and Build a Delivery Pipeline for Virtual Server Images](https://www.ibm.com/cloud/blog/design-and-build-a-delivery-pipeline-for-virtual-server-images)

Create an image using packer.  Demonstrate the roll out in two different environments:
1. simple - vpc with one instance
2. autoscale - instance group with autoscale configuration

![image](https://user-images.githubusercontent.com/6932057/188900788-18736f50-1ffe-4975-929e-cdd5df2b389c.png)


# Prepare

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

## Configure

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


See `make clean` below to remove up all the resources.

# make
Use make to invoke each of the steps that you may want to add to your pipeline, `make x` will execute one of the example steps

## make vpc
Invoke terraform in the image_tf directory to create a vpc and subnet for packer.  The `terraform output` captures the packer variables.
```
make vpc
```

## make image
Invoke Packer to create an image.  The image created is recorded in packer-manifest.json see packer docs for details. This step is **Image Pipeline** in the diagram.
```
make image
```

## make tag
Delete the tag from all images and then add the tag to the latest packer image.  The file packer-manifest.json will be used to identify the latest image.
```
make tag
```

## make simple
Invoke terraform in the simple_tf directory to create a vpc, subnet and instance with the image just tagged in `make tag`.
```
make simple
```

## Test simple via curl
Find the public ip address of the simple instance and curl:
```
public_ip=$(terraform output -state simple_tf/terraform.tfstate -raw public_ip)
echo $public_ip
while sleep 1; do curl $public_ip; done
```

or:
```
make simple_curl
```

## make autoscale
![image](https://user-images.githubusercontent.com/6932057/188898113-6c9743ce-0590-407c-bc8d-6b16fdf699a3.png)

The autoscale production make target contains two steps, both executed in the vpc_autoscale_tf directory:
- apply.sh - wrapper around `terraform apply` that juggles two instance_template resources.
- roll.sh - Slowly delete each of the members of the instance_group allowing them to be replaced by the latest packer image

```
make autoscale
```

## Test autoscale via curl
Find the public DNS name of the load balancer and curl:
```
load_balancer=$(terraform output -state vpc_autoscale_tf/terraform.tfstate -raw load_balancer_hostname)
echo $load_balancer
while sleep 1; do curl $load_balancer; done
```

or:
```
make autoscale_curl
```

## make rollout
Now that everythine is working you can make a change to the image and roll out a new version.  The contents of the image are defined in ubuntu-hello.pkr.hcl look for these sections:
```
locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  version = local.timestamp
  ...
}

  provisioner "shell" {
    inline = [
      "set -x",
      "echo '@reboot echo ${local.version} $(hostname) $(hostname -I) > /var/www/html/index.html' | crontab",
      ...
```

The echo is putting a line into the crontab file that is executed on reboot to write some text to index.html.  Evaluating `hostname` and `hostname -I` on the instance during boot provides some info about the VPC instance.  The `${local.version}` is evaluated by packer and is derived from the timestamp at the time packer was run.  Add some code to the echo line like this:


```
  provisioner "shell" {
    inline = [
      "set -x",
      "echo '@reboot echo FUN ${local.version} $(hostname) $(hostname -I) > /var/www/html/index.html' | crontab",
      ...
```

Steps to roll out a new image:
```
make image
make tag
make simple
make autoscale
```

This will create a new image and provision.  Test via curl described above.  You can transfer the `public_ip` and `load_balancer` variables to your laptop computer to watch as the new images are rolled out.

## make clean
Clean up all of the resources.