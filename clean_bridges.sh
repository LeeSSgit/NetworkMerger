#!/bin/bash

if [ $# -eq 0 ];
then
        echo "Please, specify the IP of system, which should be cleaned"
else
	ssh root@$1 'for BR in $(ovs-vsctl list-br); do ovs-vsctl del-br $BR; done'
fi
