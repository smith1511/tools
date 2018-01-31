#!/bin/bash -x

# Install NFS
yum install -y nfs-utils
systemctl enable nfs-server.service
systemctl start nfs-server.service

# Install Azure CLI
yum install -y epel-release
yum group install -y "Development Tools"
rpm --import https://packages.microsoft.com/keys/microsoft.asc
sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
yum check-update
yum install -y python34
yum install -y azure-cli

/bin/bash -c 'wget  -O - https://raw.githubusercontent.com/Azure/batch-insights/master/centos.sh | bash'

# Allow sudo to run within scripts
sed -i -e 's/^Defaults    requiretty.*/ #Defaults    requiretty/g' /etc/sudoers

# Allow tvm user to sudo
echo "_azbatch ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

reboot=false
if ! grep -q "root soft memlock" /etc/security/limits.conf; then
    echo "root soft memlock unlimited" >> /etc/security/limits.conf
    echo "root hard memlock unlimited" >> /etc/security/limits.conf
    echo "root soft stack unlimited" >> /etc/security/limits.conf
    echo "root hard stack unlimited" >> /etc/security/limits.conf
    
    echo "ulimit -s unlimited" >> /root/.bashrc
    echo "ulimit -l unlimited" >> /root/.bashrc

    # If RDMA modules detected, setup required env vars
    lsmod | grep -q "^rdma"
    if [ $? -eq 0 ]; then
        echo "# IB Config for MPI" > /etc/profile.d/mpi.sh
        echo "export I_MPI_FABRICS=shm:dapl" >> /etc/profile.d/mpi.sh
        echo "export I_MPI_DAPL_PROVIDER=ofa-v2-ib0" >> /etc/profile.d/mpi.sh
        echo "export I_MPI_DYNAMIC_CONNECTION=0" >> /etc/profile.d/mpi.sh
    fi

    reboot=true
fi

if [ "$reboot" = "true" ]; then
    reboot &
    exit 0
fi

exit 0
