#!/bin/bash

function clean_bridges {
	echo "start cleaning on $1"
	ssh root@$1 'for BR in $(ovs-vsctl list-br); do ovs-vsctl del-br $BR; done'
}

function SingleTopo {
        sIP=$1
        echo "start deploy topology with one station"
        clean_bridges "$1"
}

if [ $# -eq 0 ];
then
	echo "please, input all station's IPs separated by space"
	read -a stations
	SCount=${#stations[@]}
	echo "okay, You have entered $SCount VM's"

	if [ $SCount -eq 1 ];
	then
		SingleTopo "${stations[0]}"
	fi
	if [ $SCount -eq 1 ];
        then
		echo "two station topology! Cool!"
	fi
	if [ $SCount -eq 1 ];
		echo "oh my gosh, really?"
        then
	
else
	echo "Wow! Arguments! I'm not ready yet to be honest."
fi
