locals {
  master_name = "hive"
  sensor_names = [for i in range(1, 3) : "honey-${i}"]
  honey_names = concat([local.master_name], local.sensor_names)
  honey_zones = ["europe-west4-a", "asia-east1-a", "us-west2-a", "australia-southeast1-c"]

  honey_map = { for idx, name in local.honey_names :
    name => (
      idx < length(local.honey_zones) ? local.honey_zones[idx] : var.gcp_zone
    )
  }
}

# https://gcloud-compute.com/instances.html
resource "google_compute_instance" "honey" {

  for_each = local.honey_map

  name = each.key
  zone = each.value
  machine_type = "n2d-highmem-2"
  tags = ["honey"]

  depends_on = [
    # google_service_account.registry_server_account, 
    #             google_project_iam_member.vm_artifact_reader
  ]

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-12-bookworm-v20240213"
      size = 25
    }
  }

  attached_disk {
    source = google_compute_disk.db_volume[each.key].id
    device_name = "volume-${each.key}"
  }

  metadata = {
    ssh-keys = "root:${file(var.pub_key)}"
    startup-script = templatefile("${path.module}/startup.sh.tpl", {
      DEVICE = "/dev/disk/by-id/google-volume-${each.key}"
      MOUNT_POINT = "/mnt/tpot"
      is_master = each.key == local.master_name ? "true" : "false"
      master_ip = ""
    #   master_ip = each.key == local.master_name ? "" : google_compute_instance.honey[local.master_name].network_interface[0].network_ip
    })
  }

  network_interface {
    network = "default"
    access_config {}
  }
#   network_interface {
#     network = google_compute_network.aleex_vpc.name
#     # subnetwork = google_compute_subnetwork.aleex_subnet.name

#     access_config {}
#   }

  lifecycle {
    ignore_changes = [boot_disk[0].initialize_params[0].image]
  }

  connection {
    host = self.network_interface[0].access_config[0].nat_ip
    user = "root"
    private_key = file(var.pvt_key)
    timeout = "2m"
  }
}

# ---------------------
# Persistent Disks
# ---------------------
resource "google_compute_disk" "db_volume" {
  for_each = local.honey_map

  name = "volume-${each.key}"
  type = "pd-ssd"
  zone = each.value
  size = 80
}

# resource "google_compute_disk" "db_volume" {
#   name = "volume-honey-01"
#   type = "pd-ssd"
#   zone = var.gcp_zone
#   size = 80
# }
