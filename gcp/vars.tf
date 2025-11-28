variable "gcp_project" {
  description = "GCP project ID"
  type = string
}

variable "gcp_region" {
  description = "Default region for resources"
  type = string
  default = "europe-west4"
}

variable "gcp_zone" {
  description = "Default zone for compute instances"
  type = string
  default = "europe-west4-a"
}

locals {
  gcp_region = substr(var.gcp_zone, 0, length(var.gcp_zone) - 2)
}

variable "gcp_credentials_file" {
  description = "Path to the GCP service account JSON key"
  type = string
}

variable "pub_key" {
  description = "Path to public key to connect to nodes (e.g. ~/.ssh/id_rsa.pub)"
  type = string
}

variable "pvt_key" {
  description = "Path to private key to connect to nodes (e.g. ~/.ssh/id_rsa)"
  type = string
}

# terraform apply -var "do_token =${DO_TOKEN}" -var "stop_tpot =true"
variable "stop_tpot" {
  description = "Stop the tpot service on all nodes and re-enable port 22"
  type = bool
  default = false
}

variable "start_tpot" {
  description = "Start the tpot service after re-enabling port 64295 for ssh"
  type = bool
  default = false
}
