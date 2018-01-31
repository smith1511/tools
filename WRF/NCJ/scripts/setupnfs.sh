#!/bin/bash
#
# This script is run by the Batch Coordination command line.
# The goal is to configure and start a NFS server on the master 
# tasklet, and a client on all others.  The clients will mount the
# share under $AZ_BATCH_TASK_SHARED_DIR/share.
#
# If the job/task is only run on a single node, this script will not be run
# however the same directory will be used.
#
set -x

if [ -z "$AZ_BATCH_IS_CURRENT_NODE_MASTER" ]; then
    echo "Not a multi instance task"
    exit 1
fi

SHARE_PATH=$AZ_BATCH_TASK_SHARED_DIR/share

if [ "$AZ_BATCH_IS_CURRENT_NODE_MASTER" = "true" ]; then
    echo "Master"
    
    mkdir -p $SHARE_PATH
    chmod 777 -R $SHARE_PATH
    
    sudo /bin/bash -c "echo \"$SHARE_PATH 10.0.0.0/24(rw,async,no_root_squash,no_all_squash)\" > /etc/exports"
    
    sudo systemctl reload nfs-server.service
else
    echo "Not master"
    
    mkdir -p $SHARE_PATH
    
    masterIp="`echo $AZ_BATCH_MASTER_NODE | awk -F: '{print $1}'`"
    
    count=0
    while true; do
    
        if [ $count -gt 20 ]; then
            echo "Timeout waiting for NFS share"
            exit 1
        fi
        
        sudo showmount -e $masterIp | grep "^$SHARE_PATH"
        if [ $? -eq 0 ]; then
            echo "NFS is up"
            break
        fi
        
        count=$((count+1))
        
        sleep 5
    done
    
    cat /etc/fstab | grep "^${masterIp}:$SHARE_PATH"
    if [ $? -eq 0 ]; then
        echo "Share already added to fstab"
    else
        sudo sed -i 's/^10\.0\.0\..*//g' /etc/fstab
        sudo /bin/bash -c "echo \"${masterIp}:$SHARE_PATH $SHARE_PATH    nfs4    defaults 0 0\" >> /etc/fstab"
    fi

    sudo mount | grep "^${masterIp}:$SHARE_PATH"
    if [ $? -eq 0 ]; then
        echo "Share already mounted"    
    else
        sudo mount -a
    fi
fi

exit 0
