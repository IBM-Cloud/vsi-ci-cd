#!/bin/bash
set -e

ibmcloud login --apikey $IC_API_KEY -r $TF_VAR_region
ibmcloud target -r $TF_VAR_region
instance_group_id=$(terraform output -raw instance_group_id)
group_membership_json=$(ibmcloud is instance-group-memberships $instance_group_id --output json)
group_members=$(jq -r '.[]|.id' <<< "$group_membership_json")
for member in $group_members; do
  ibmcloud is instance-group-membership-delete $instance_group_id $member --force
  sleep 30
done