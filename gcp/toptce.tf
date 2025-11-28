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
INPUT
echo "REMOVING CONFLICTING PACKAGES"
# remove conflicting services
sudo apt -y purge exim4 exim4-base exim4-config exim4-daemon-light
sudo systemctl disable systemd-resolved --now
sudo cp resolv.conf /etc/resolv.conf
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.tpot
echo "REBOOTING"
sudo reboot
echo "REBOOTED"
            EOT
        ]
    }
}

resource "null_resource" "tpotce_disable" {
    for_each = var.stop_tpot ? google_compute_instance.honey : {}

    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        command = <<-EOT
        ssh -i ${var.pvt_key} \
            -o BatchMode=yes \
            -o StrictHostKeyChecking=no \
            -p 64295  \
            debian@${each.value.network_interface[0].access_config[0].nat_ip} \
            "sh /mnt/tpot/tpotce/gcp/stop-tpot.sh"
        EOT
        interpreter = ["bash", "-c"]
    }
}

resource "null_resource" "tpotce_enable" {
    for_each = var.start_tpot ? google_compute_instance.honey : {}

    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        command = <<-EOT
        ssh -i ${var.pvt_key} \
            -o BatchMode=yes \
            -o StrictHostKeyChecking=no \
            -p 64295  \
            debian@${each.value.network_interface[0].access_config[0].nat_ip} \
            "sh /mnt/tpot/tpotce/gcp/start-tpot.sh"
        EOT
        interpreter = ["bash", "-c"]
    }
}
