sensor_ip=$1
hive_ip=$2

cd ~/tpotce/
cat <<INPUT | ./deploy.sh
y
aleex
$sensor_ip
y
$hive_ip

yes
INPUT
