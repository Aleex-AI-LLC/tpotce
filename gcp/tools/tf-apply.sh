#!/bin/bash

if [ $# -eq 0 ]; then
  echo "Error: provide path to GCP key file" >&2
  exit 1
fi

terraform apply -var "gcp_project=gen-lang-client-0916241324" -var "gcp_credentials_file=$1" -var pub_key=~/.ssh/terraform.pub -var pvt_key=~/.ssh/terraform
