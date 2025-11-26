# resource "null_resource" "setup_ssh_known_hosts" {
#     for_each = {
#         www = google_compute_instance.www
#         aleex = google_compute_instance.aleex
#     }

#     connection {
#         type = "ssh"
#         user = "root"
#         host = each.value.network_interface[0].access_config[0].nat_ip
#         private_key = file(var.pvt_key)
#     }

#     depends_on = [google_compute_firewall.provisioning]

#     provisioner "remote-exec" {
#         inline = [
#             "ssh-keyscan -H ${google_compute_instance.manager.network_interface[0].access_config[0].nat_ip} >> ~/.ssh/known_hosts",
#         ]
#     }
# }

locals {
  sensors_instances = {
    for name, inst in google_compute_instance.honey :
    name => inst if name != local.master_name
  }
}

resource "null_resource" "tpotce_install" {
    for_each = google_compute_instance.honey

    triggers = {
        always_run = timestamp()
    }

    # depends_on = [google_compute_firewall.provisioning]

    connection {
        host = each.value.network_interface[0].access_config[0].nat_ip
        type = "ssh"
        user = "debian"
        private_key = file(var.pvt_key)
        timeout = "1m"
    }

#   provisioner "file" {
#     source = "${path.module}/scripts/honey-install.sh"
#     destination = "/tmp/honey-install.sh"
#   }

    provisioner "remote-exec" {
        inline = [
            <<-EOT
sudo apt-get update -y
sudo apt-get install -y git
cd /mnt/tpot
sudo git clone https://github.com/Aleex-AI-LLC/tpotce
sudo chown -R debian tpotce
sudo chgrp -R debian tpotce
cd tpotce
cat <<INPUT | ./install.sh
y
h
aleex
y
Aleex123Aleex
Aleex123Aleex
sudo reboot
INPUT
            EOT
        ]
    }
}

resource "null_resource" "tpotce_disable" {
    for_each = google_compute_instance.honey

    triggers = {
        always_run = timestamp()
    }

    connection {
        host = each.value.network_interface[0].access_config[0].nat_ip
        type = "ssh"
        port = 64295
        user = "debian"
        private_key = file(var.pvt_key)
        timeout = "1m"
    }

provisioner "local-exec" {
  command = <<-EOT
  ssh -i ${var.pvt_key} \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=no \
    -p 64295  \
    debian@${each.value.network_interface[0].access_config[0].nat_ip} \
    "echo AAAA"
  EOT
  interpreter = ["bash", "-c"]
}

#   # Upload your known-good script
#   provisioner "file" {
#     source = "stop-tpot.sh"
#     destination = "/tmp/stop-tpot.sh"
#   }

#   # Execute it explicitly with bash
#   provisioner "remote-exec" {
#     inline = [
#       "ls -l /tmp/stop-tpot.sh"
#     ]
#   }

#     provisioner "remote-exec" {
#         inline = [
#             <<-EOT
# sudo systemctl stop tpot
# sudo cp /etc/ssh/sshd_config.default /etc/ssh/sshd_config
# sudo systemctl restart ssh
# sudo ss -tlnp
#             EOT
#         ]
#     }
}

# resource "null_resource" "docker_install" {
#     for_each = {
#         manager = google_compute_instance.manager
#         www = google_compute_instance.www
#         aleex = google_compute_instance.aleex
#     }

#     triggers = {
#         always_run = timestamp()
#     }

#     depends_on = [google_compute_firewall.provisioning]

#     connection {
#         host = each.value.network_interface[0].access_config[0].nat_ip
#         type = "ssh"
#         user = "root"
#         private_key = file(var.pvt_key)
#         timeout = "2m"
#     }

#     provisioner "remote-exec" {
#         inline = [
#             "export PATH=$PATH:/usr/bin",
#             "apt-get update -y",
#             "apt-get install -y docker.io docker-compose",
#             "systemctl start docker",
#             "mkdir -p /usr/local/scytale",
#             "mkdir -p /usr/local/scytale/ollama/models/"
#         ]
#     }
# }
