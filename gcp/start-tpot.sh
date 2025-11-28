#!/bin/bash
sudo cp /etc/ssh/sshd_config.tpot /etc/ssh/sshd_config
sudo systemctl restart ssh
sudo ss -tlnp
sudo systemctl start tpot
