#!/bin/bash

# Enable root SSH
cp -rp /home/_azbatch/.ssh /root/
chown -R root:root /root/.ssh
sed -i 's/PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
systemctl reload sshd.service

exit 0
