#!/bin/bash
# remove all images found in the packer-manifest file
set -e

ibmcloud login --apikey $IC_API_KEY -r $TF_VAR_region
images=$(jq -r '.builds[].artifact_id' packer-manifest.json)
ibmcloud is image-delete $images --force
