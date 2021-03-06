#!/bin/bash

exec 1> >(logger -s -t $(basename $0)) 2>&1

declare -a CONFIG

function read_conf_file {
	exec 10<&0
	exec < /root/NetworkMerger/$1
	local let count=0
	
	while read LINE; do
		CONFIG[$count]=$LINE
		((count++))
	done

	exec 0<&10 10<&-
}

if [ $# -eq 0 ];
then 
	echo "can't start without parameters"
else
	if [ $1 = "single.conf" ];
	then
		read_conf_file "single.conf"
		brname="dvs"
		echo "config file loaded"
		ifconfig eth1 0
		ifconfig eth2 0
		echo "eth0 and eth1 detached from ip stack"
		ovs-vsctl add-br $brname -- add-port $brname eth1 -- add-port $brname eth2
	#Take ofport numbers of added ports
		long=$(ovs-ofctl show $brname | grep eth1)
		ofport_eth1=${long:1:1}
		long=$(ovs-ofctl show $brname | grep eth2)
		ofport_eth2=${long:1:1}
		echo "bridge $brname created and ports added"
	#Set OpenFlow rules on switch
		ovs-ofctl del-flows $brname
		ovs-ofctl add-flow $brname priority=100,in_port=$ofport_eth1,idle_timeout=0,action=output:$ofport_eth2
		ovs-ofctl add-flow $brname priority=100,in_port=$ofport_eth2,idle_timeout=0,action=output:$ofport_eth1
		ovs-ofctl add-flow $brname priority=0,action=normal
		echo "OpenFlow rules added for ports"
		echo "Adding address for $brname ..."
		ip addr add ${CONFIG[0]}/${CONFIG[1]} dev $brname
		echo "IP is: ${CONFIG[0]}. Specify it as a default gateway for joined networks"
		echo "done!" 
	fi

	if [ $1 = "double.conf" ];
	then
		read_conf_file "double.conf"
		brname="dvs"
		echo "config file loaded"
		ifconfig eth1 0
		echo "eth1 detached from ip stack"
		ovs-vsctl add-br $brname -- add-port $brname eth1
		#long=$(ovs-ofctl show $brname | grep eth1)
		#ofport_eth1=${long:1:1}
		echo "bridge $brname created and port eth1 added"
		echo "Adding address for $brname ..."
		ip addr add ${CONFIG[0]}/${CONFIG[1]} dev $brname
		echo "IP is: ${CONFIG[0]}. Specify it as a default gateway for joined networks"
		ovs-vsctl add-port $brname vtep -- set interface vtep type=vxlan option:remote_ip=${CONFIG[2]} option:key=flow ofport_request=10
		echo "vxlan tunnel endpoint added to $brname"
		for DEV in $(ifconfig -a | sed 's/[ \t].*//;/^\(lo\|\)$/d'); 
		do
			ip link set mtu 9000 dev $DEV; 
			echo "MTU for $DEV is 9000"
		done;
		echo "done!"
	fi
fi
