resource "google_compute_network" "aleex_vpc" {
  name = "aleex-vpc"
  auto_create_subnetworks = true
}

# resource "google_compute_subnetwork" "aleex_subnet" {
#   name = "scytale-subnet"
#   ip_cidr_range = "10.10.10.0/24"
#   region = "europe-west4"
#   network = google_compute_network.scytale_vpc.id
# }
