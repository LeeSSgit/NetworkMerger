#!/bin/bash

#sudo ip addr add 10.10.10.1/24 dev eth0
#sudo ip link set dev eth1 up
#sudo ip addr add 192.168.0.1/24 dev eth1

if [ $# -eq 0 ];
then
	echo "started without arguments"
	vxlan_name=vxlan1
	vxlan_id=1
	vxlan_ip=192.168.0.100
	echo "vxlan name and vxlan id configured by default"
else
	echo "started with arguments"
	vxlan_name=$1
	vxlan_id=$2
	vxlan_ip=$3
	echo "vxlan name is $vxlan_name"
	echo "vxlan id is $vxlan_id"
fi

sudo ip link add $vxlan_name type vxlan id $vxlan_id group 239.0.0.1 port 0 0 dev eth1
sudo ip addr add $vxlan_ip/24 dev $vxlan_name
sudo ip link set dev $vxlan_name up 
