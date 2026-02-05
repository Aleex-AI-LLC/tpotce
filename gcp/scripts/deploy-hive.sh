hive_ip = $1

# wait for hive/sensors reboot
sleep 180

# remove all sensors from known_hosts
cp ~/.ssh/known_hosts ~/.ssh/known_hosts.backup
grep -v ":64295" ~/.ssh/known_hosts.backup > ~/.ssh/known_hosts

# generate keypair and copy it to the sensor
[ -e id_rsa ] || ssh-keygen -t rsa -b 4096 -f id_rsa -N '' -q
scp -i ${var.pvt_key} \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=no \
    -P 64295  \
    id_rsa* \
    aleex@$hive_ip:~/.ssh/
EOT

# this is ok to use only IP addresses; change the addtext option to:
# -addext "subjectAltName = IP:172.17.0.1, IP:, DNS:my.primary.domain, DNS:my.secondary.domain"
# to include domain names:
sudo openssl req \
    -nodes \
    -x509 \
    -sha512 \
    -newkey rsa:8192 \
    -keyout ~/tpotce/nginx.key \
    -out ~/tpotce/nginx.crt \
    -days 3650 \
    -subj '/C=AU/ST=Some-State/O=Internet Widgits Pty Ltd' \
    -addext "subjectAltName = IP:172.17.0.1, IP:$hive_ip"

sudo chmod 774 ~/tpotce/data/nginx/cert/*
sudo chown tpot:tpot ~/tpotce/data/nginx/cert/*
