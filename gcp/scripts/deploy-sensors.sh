#!/usr/bin/env bash

key=$1
hive=$2

shift 2

for inst in "$@"; do
    ssh -i ${key} \
        -o BatchMode=yes \
        -o StrictHostKeyChecking=no \
        -p 64295 \
        aleex@$hive <<INPUT
    cd ~/tpotce/gcp
    echo "DEPLOYING SENSOR $inst"
#    bash deploy-sensor.sh $inst $hive_ip
INPUT
done

