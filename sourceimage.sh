#!/bin/bash
export TF_VAR_image_name=$(jq -r '.builds[-1].custom_data.image_name' packer-manifest.json)