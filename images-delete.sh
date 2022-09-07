#!/bin/bash
# remove all
set -x

tag=$1

ibmcloud login --apikey $IC_API_KEY
images=$(jq -r '.builds[].artifact_id' packer-manifest.json)
ibmcloud is image-delete $images --force