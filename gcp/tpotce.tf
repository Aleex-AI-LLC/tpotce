locals {
  hive = one(
    [for inst in google_compute_instance.honey : inst if inst.name == "hive"]
  )
}

resource "null_resource" "tpotce_hive_install" {
    for_each = {
        for k, inst in google_compute_instance.honey :
        k => inst
        if inst.name == "hive"
    }

    depends_on = [google_compute_instance.honey]

    connection {
        host = each.value.network_interface[0].access_config[0].nat_ip
        type = "ssh"
        user = "aleex"
        private_key = file(var.pvt_key)
        timeout = "1m"
    }

    provisioner "remote-exec" {
        inline = [
            <<-EOT
echo "INSTALLING TPOT"
sudo apt-get update -y
sudo apt-get install -y git
sudo cp -n /etc/ssh/sshd_config /etc/ssh/sshd_config.default
cd ~
git clone https://github.com/Aleex-AI-LLC/tpotce
cd tpotce
mkdir -p /mnt/tpot/data
groupadd --gid 2000 tpot
useradd --uid 2000 --gid tpot --system --shell /bin/false --home /nonexistent tpot
chown -R tpot /mnt/tpot/
chgrp -R tpot /mnt/tpot/
ln -s /mnt/tpot/data data
cat <<INPUT | ./install.sh
y
h
aleex
y
Aleex123Aleex
Aleex123Aleex
INPUT
echo "REMOVING CONFLICTING PACKAGES"
sudo apt -y purge exim4 exim4-base exim4-config exim4-daemon-light
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.tpot
cp ssh.config ~/.ssh/config
chmod 644 ~/.ssh/config
echo "REBOOTING"
sudo reboot
echo "REBOOTED"
            EOT
        ]
    }
}

resource "null_resource" "tpotce_sensor_install" {
    for_each = {
        for k, inst in google_compute_instance.honey :
        k => inst
        if inst.name != "hive"
    }

    depends_on = [google_compute_instance.honey]

    connection {
        host = each.value.network_interface[0].access_config[0].nat_ip
        type = "ssh"
        user = "aleex"
        private_key = file(var.pvt_key)
        timeout = "1m"
    }

    provisioner "remote-exec" {
        inline = [
            <<-EOT
echo "INSTALLING TPOT ${each.key}"
sudo apt-get update -y
sudo apt-get install -y git
sudo cp -n /etc/ssh/sshd_config /etc/ssh/sshd_config.default
cd ~
git clone https://github.com/Aleex-AI-LLC/tpotce
cd tpotce
mkdir -p /mnt/tpot/data
groupadd --gid 2000 tpot
useradd --uid 2000 --gid tpot --system --shell /bin/false --home /nonexistent tpot
chown tpot /mnt/tpot/
chgrp tpot /mnt/tpot/
ln -s /mnt/tpot/data data
cat <<INPUT | ./install.sh
y
s
INPUT
echo "REMOVING CONFLICTING PACKAGES"
sudo apt -y purge exim4 exim4-base exim4-config exim4-daemon-light
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.tpot
echo "REBOOTING"
sudo reboot
echo "REBOOTED"
            EOT
        ]
    }
}

resource "null_resource" "tpotce_hive_key" {

    for_each = {
        for k, inst in google_compute_instance.honey :
        k => inst
        if inst.name == "hive"
    }

    depends_on = [null_resource.tpotce_sensor_install]

    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        interpreter = ["bash", "-c"]
        command = <<-EOT
        bash deploy-hive.sh ${each.value.network_interface[0].access_config[0].nat_ip}
        EOT
    }
}

resource "null_resource" "tpotce_sensor_key" {

    for_each = {
        for k, inst in google_compute_instance.honey :
        k => inst
        if inst.name != "hive"
    }

    depends_on = [null_resource.tpotce_hive_key]

    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        interpreter = ["bash", "-c"]
        command = <<-EOT
        cat id_rsa.pub | 
        ssh -i ${var.pvt_key} \
            -o BatchMode=yes \
            -o StrictHostKeyChecking=no \
            -p 64295  \
            aleex@${each.value.network_interface[0].access_config[0].nat_ip} \
            "cat >> ~/.ssh/authorized_keys; uniq ~/.ssh/authorized_keys > ~/authorized_keys ; mv authorized_keys ~/.ssh/authorized_keys"
        EOT
    }
}

resource "null_resource" "tpotce_deploy_sensors" {

    for_each = {
        for k, inst in google_compute_instance.honey :
        k => inst
        if inst.name != "hive"
    }

    depends_on = [null_resource.tpotce_sensor_key]

    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        interpreter = ["bash", "-c"]
        command = <<-EOT
        ssh -i ${var.pvt_key} \
            -o BatchMode=yes \
            -o StrictHostKeyChecking=no \
            -p 64295 \
            aleex@${local.hive.network_interface[0].access_config[0].nat_ip} \
            "bash -i <<INPUT
cd ~/tpotce/gcp
echo \"DEPLOY SENSOR ${each.value.network_interface[0].access_config[0].nat_ip}\"
bash deploy-sensor.sh ${each.value.network_interface[0].access_config[0].nat_ip} \
                      ${local.hive.network_interface[0].access_config[0].nat_ip}
            INPUT"
        EOT
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
            aleex@${each.value.network_interface[0].access_config[0].nat_ip} \
            "bash -i <<INPUT
sh ~/tpotce/gcp/stop-tpot.sh"
cp /etc/ssh/sshd_config.default /etc/ssh/sshd_config
systemctl restart ssh.service
            INPUT"
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
            aleex@${each.value.network_interface[0].access_config[0].nat_ip} \
            "bash -i <<INPUT
sh ~/tpotce/gcp/start-tpot.sh"
cp /etc/ssh/sshd_config.default /etc/ssh/sshd_config
systemctl restart ssh.service
            INPUT"
        EOT
        interpreter = ["bash", "-c"]
    }
}
