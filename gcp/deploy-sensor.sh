sensor_ip=$1
hive_ip=$2

ssh -o StrictHostKeyChecking=no -o BatchMode=yes -p 64295 aleex@$sensor_ip "cd"

cd ~/tpotce/
cat <<INPUT | ./deploy.sh
y
aleex
$sensor_ip
y
$hive_ip

yes
INPUT
