#!/bin/bash
# move the tag by first removing it from all images then adding it to the image provided by TF_VAR_image_name
set -e

tag=${TF_VAR_prefix}-stage

ibmcloud login --apikey $IC_API_KEY -r $TF_VAR_region
luceneQuery='service_name:is AND type:image AND tags:"'$tag'"'
searchJson=$(ibmcloud resource search --output json "$luceneQuery")
for resourceCrn in $(jq -r '.items|.[].crn' <<< "$searchJson"); do
  ibmcloud resource tag-detach --tag-names $tag --resource-id $resourceCrn
done

ibmcloud resource tag-attach --tag-names $tag --resource-name $TF_VAR_image_name
