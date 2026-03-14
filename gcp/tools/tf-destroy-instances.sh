#!/bin/sh

if [ $# -eq 0 ]; then
  echo "Error: provide path to GCP key file" >&2
  exit 1
fi


terraform plan -destroy -out=terraform.tfplan \
$(terraform state list | grep google_compute_instance | sed 's/^/-target=/') \
-var "gcp_project=rank-mdr" -var "gcp_credentials_file=$1" -var pub_key=~/.ssh/terraform.pub -var pvt_key=~/.ssh/terraform

terraform apply terraform.tfplan

rm terraform.tfplan
