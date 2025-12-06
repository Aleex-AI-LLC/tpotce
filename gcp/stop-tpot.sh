#!/bin/bash
sudo systemctl stop tpot
sudo systemctl disable tpot
sudo cp /etc/ssh/sshd_config.default /etc/ssh/sshd_config
sudo systemctl restart ssh
sudo ss -tlnp
