locals {
  hive = one(
    [for inst in google_compute_instance.honey : inst if inst.name == "hive"]
  )

  hive_map = {
    for inst in google_compute_instance.honey :
    inst.name => inst
    if inst.name == "hive"
  }

  sensors = {
    for k, inst in google_compute_instance.honey :
        k => inst
        if inst.name != "hive"
    }

}

resource "null_resource" "tpotce_hive_install" {
    for_each = local.hive_map

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
sudo groupadd --gid 2000 tpot
sudo useradd --gid tpot --system --shell /bin/false --home /nonexistent tpot
sudo mkdir -p /mnt/tpot/data/
sudo chown -R tpot /mnt/tpot/
sudo chgrp -R tpot /mnt/tpot/
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
# echo "DISABLE GLOBAL DNS"
# echo "127.0.0.1 `hostname`" | sudo tee -a  /etc/hosts
# sudo systemctl disable systemd-resolved
# sudo systemctl stop systemd-resolved
# sudo rm /etc/resolv.conf
# echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
echo "REBOOTING"
sudo reboot
echo "REBOOTED"
            EOT
        ]
    }
}

resource "null_resource" "tpotce_sensor_install" {
    for_each = local.sensors

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
sudo mkdir -p /mnt/tpot/data/
sudo groupadd --gid 2000 tpot
sudo useradd --uid 2000 --gid tpot --system --shell /bin/false --home /nonexistent tpot
sudo chown tpot /mnt/tpot/
sudo chgrp tpot /mnt/tpot/
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
    for_each = local.hive_map

    depends_on = [null_resource.tpotce_hive_install,
                  null_resource.tpotce_sensor_install]

    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        interpreter = ["bash", "-c"]
        command = <<-EOT
        echo "WAITING FOR HIVE TO REBOOT"
        sleep 240
        echo "WAKING UP"
        cp ~/.ssh/known_hosts ~/.ssh/known_hosts.backup
        grep -v ":64295" ~/.ssh/known_hosts.backup > ~/.ssh/known_hosts
        echo "GENERATING/UPLOADING SSH KEY"
        [ -e id_rsa ] || ssh-keygen -t rsa -b 4096 -f id_rsa -N '' -q
        scp -i ${var.pvt_key} \
            -o BatchMode=yes \
            -o StrictHostKeyChecking=no \
            -P 64295  \
            id_rsa* \
            aleex@${each.value.network_interface[0].access_config[0].nat_ip}:~/.ssh/
        echo "GENERATING SSL CERT"
        ssh -i ${var.pvt_key} \
            -o BatchMode=yes \
            -o StrictHostKeyChecking=no \
            -p 64295  \
            aleex@${each.value.network_interface[0].access_config[0].nat_ip} \
        <<INPUT
echo "*******************************************"
echo "*******************************************"
echo "*******************************************"
echo "*******************************************"
echo "SSL CERTIFICATE"
echo "*******************************************"
echo "*******************************************"
echo "*******************************************"
echo "*******************************************"
openssl req \
    -nodes \
    -x509 \
    -sha512 \
    -newkey rsa:8192 \
    -keyout ~/tpotce/nginx.key \
    -out ~/tpotce/nginx.crt \
    -days 365 \
    -subj '/C=ES/ST=Madrid/O=Aleex/CN=internal-web' \
    -addext 'subjectAltName=IP:172.17.0.1,IP:${each.value.network_interface[0].access_config[0].nat_ip}'
sudo mkdir -p ~/tpotce/data/nginx/cert/
sudo cp ~/tpotce/nginx.key ~/tpotce/nginx.crt ~/tpotce/data/nginx/cert/
sudo chmod 774 ~/tpotce/data/nginx/cert/*
sudo chown tpot:tpot ~/tpotce/data/nginx/cert/*
INPUT
        EOT
    }
}

resource "null_resource" "tpotce_sensor_key" {
    for_each = local.sensors

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
            -p 64295 \
            aleex@${each.value.network_interface[0].access_config[0].nat_ip} \
            "cat >> ~/.ssh/authorized_keys; uniq ~/.ssh/authorized_keys > ~/authorized_keys ; mv authorized_keys ~/.ssh/authorized_keys"
        EOT
    }
}

resource "null_resource" "tpotce_deploy_sensors" {
    triggers = {
        always_run = timestamp()
    }

    depends_on = [
        null_resource.tpotce_sensor_key
    ]

    provisioner "local-exec" {
        interpreter = ["bash", "-c"]

        environment = {
            ordered_honeys = nonsensitive(join(" ", [for inst in local.sensors : inst.network_interface[0].access_config[0].nat_ip]))
            hive_ip = local.hive.network_interface[0].access_config[0].nat_ip
        }

        command = <<-EOT
for inst in $ordered_honeys; do
    ssh -i ${var.pvt_key} \
        -o BatchMode=yes \
        -o StrictHostKeyChecking=no \
        -p 64295 \
        aleex@$hive_ip <<INPUT
    cd ~/tpotce/gcp
    echo "DEPLOYING SENSOR $inst"
    bash deploy-sensor.sh $inst $hive_ip
INPUT
done
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
            <<INPUT
sudo systemctl stop tpot
docker compose -f docker-compose.yml down -v
sudo cp /etc/ssh/sshd_config.default /etc/ssh/sshd_config
sudo systemctl restart ssh.service
INPUT
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
            <<INPUT
sudo systemctl start tpot
sudo cp /etc/ssh/sshd_config.default /etc/ssh/sshd_config
sudo systemctl restart ssh.service
INPUT
        EOT
        interpreter = ["bash", "-c"]
    }
}

# resource "null_resource" "tpotce_reboot_hive" {
#     for_each = var.reboot_tpot ? local.hive_map : {}

#     triggers = {
#         always_run = timestamp()
#     }

#     provisioner "local-exec" {
#         command = <<-EOT
#         ssh -i ${var.pvt_key} \
#             -o BatchMode=yes \
#             -o StrictHostKeyChecking=no \
#             -p 64295  \
#             aleex@${each.value.network_interface[0].access_config[0].nat_ip} \
#             <<INPUT
# echo "REBOOTING " ${each.key}
# sudo reboot
# INPUT
#         EOT
#         interpreter = ["bash", "-c"]
#     }
# }

# resource "null_resource" "tpotce_reboot_sensors" {
#     for_each = var.reboot_tpot ? local.sensors : {}

#     triggers = {
#         always_run = timestamp()
#     }

#     depends_on = [
#         null_resource.tpotce_reboot_hive
#     ]

#     provisioner "local-exec" {
#         command = <<-EOT
#         ssh -i ${var.pvt_key} \
#             -o BatchMode=yes \
#             -o StrictHostKeyChecking=no \
#             -p 64295  \
#             aleex@${each.value.network_interface[0].access_config[0].nat_ip} \
#             <<INPUT
# echo "REBOOTING " ${each.key}
# sudo reboot
# INPUT
#         EOT
#         interpreter = ["bash", "-c"]
#     }
# }

resource "null_resource" "tpotce_reboot" {
    count = var.reboot_tpot ? 1 : 0

    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        interpreter = ["bash", "-c"]
        environment = {
            ordered_honeys = nonsensitive(join(" ", [for inst in local.sensors : inst.network_interface[0].access_config[0].nat_ip]))
            hive_ip = local.hive.network_interface[0].access_config[0].nat_ip
        }
        command = <<-EOT
    ssh -i ${var.pvt_key} \
        -o BatchMode=yes \
        -o StrictHostKeyChecking=no \
        -p 64295 \
        aleex@$hive_ip <<INPUT
echo "REBOOTING HIVE"
sudo reboot
INPUT
for inst in $ordered_honeys; do
    ssh -i ${var.pvt_key} \
        -o BatchMode=yes \
        -o StrictHostKeyChecking=no \
        -p 64295 \
        aleex@$inst <<INPUT
echo "REBOOTING " $inst
sudo reboot
INPUT
done
EOT
    }
}

# resource "null_resource" "tpotce_reboot" {
#     for_each = var.reboot_tpot ? google_compute_instance.honey : {}

#     triggers = {
#         always_run = timestamp()
#     }

#     provisioner "local-exec" {
#         interpreter = ["bash", "-c"]
#         command = <<-EOT
#         ssh -i ${var.pvt_key} \
#             -o BatchMode=yes \
#             -o StrictHostKeyChecking=no \
#             -p 64295  \
#             aleex@${each.value.network_interface[0].access_config[0].nat_ip} \
#             <<INPUT
# echo "REBOOTING " $inst
# sudo reboot
# INPUT
#         EOT
#     }
# }

resource "null_resource" "tpotce_status" {
    for_each = var.status_tpot ? google_compute_instance.honey : {}

    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        interpreter = ["bash", "-c"]
        command = <<-EOT
        ssh -i ${var.pvt_key} \
            -o BatchMode=yes \
            -o StrictHostKeyChecking=no \
            -p 64295  \
            aleex@${each.value.network_interface[0].access_config[0].nat_ip} \
            <<INPUT
echo "*****************************"
echo "STATUS " ${each.key}
echo "*****************************"
docker ps --format '{{.Names}}: {{.Status}}'
docker ps -a --format '{{.Names}}: {{.Status}}' | grep -v Up; true
INPUT
        EOT
    }
}
