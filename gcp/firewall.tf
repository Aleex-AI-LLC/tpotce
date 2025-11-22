# Public node firewall (SSH, HTTP-alt, HTTPS, Swarm management, etc.)
resource "google_compute_firewall" "public_node" {
  name = "aleex-honey-firewall"
  network = google_compute_network.aleex_vpc.name

  allow {
    protocol = "tcp"
    ports = ["22", "64295", "8080", "443"]
  }
  allow {
    protocol = "tcp"
    ports = ["2377", "7946"]
  }
  allow {
    protocol = "udp"
    ports = ["7946", "4789"]
  }

  source_ranges = [
    "0.0.0.0/0",
    # google_compute_subnetwork.aleex_subnet.ip_cidr_range
  ]

  target_tags = ["honey"]
}

# # Public chat firewall (port 8000 open)
# resource "google_compute_firewall" "public_chat" {
#   name = "public-chat-firewall"
#   network = google_compute_network.aleex_vpc.name

#   allow {
#     protocol = "tcp"
#     ports = ["8000"]
#   }

#   source_ranges = ["0.0.0.0/0"]

#   target_tags = ["honey"]
# }

# # Internal nodes firewall (full TCP/UDP/ICMP inside VPC only)
# resource "google_compute_firewall" "internal_nodes" {
#   name = "internal-nodes-firewall"
#   network = google_compute_network.aleex_vpc.name

#   allow {
#     protocol = "tcp"
#     ports = ["0-65535"]
#   }
#   allow {
#     protocol = "udp"
#     ports = ["0-65535"]
#   }
#   allow {
#     protocol = "icmp"
#   }

#   source_ranges = [google_compute_subnetwork.aleex_subnet.ip_cidr_range]

#   target_tags = ["manager", "aleex"]
# }

# # Provisioning firewall (allow all TCP/UDP from anywhere)
# resource "google_compute_firewall" "provisioning" {
#   name = "provisioning-fw"
#   network = google_compute_network.aleex_vpc.name

#   allow {
#     protocol = "tcp"
#     ports = ["0-65535"]
#   }
#   allow {
#     protocol = "udp"
#     ports = ["0-65535"]
#   }

#   source_ranges = ["0.0.0.0/0"]

#   target_tags = ["manager", "aleex", "www"]
# }