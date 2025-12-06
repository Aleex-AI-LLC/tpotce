resource "google_compute_firewall" "honey" {
  name = "aleex-honey-firewall"
  network = google_compute_network.aleex_vpc.name

  allow {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["honey"]
}
