#!/bin/bash

function clean_bridges {
	echo "start cleaning on $1"
	ssh root@$1 'for BR in $(ovs-vsctl list-br); do ovs-vsctl del-br $BR; done'
}

function single_topo {
        sIP=$1
	
	echo "please, specify the bridge IP which should be default gateway for hosts in both networks"
	echo -n "IP: "
	read GWIP
	echo -n "Mask: "
	read GWNM

	if validate_ip "$GWIP";
	then
		echo "ip is in valid format"
	else
		echo "ip is invalid. Halting..."
		exit 1
	fi 

	if validate_nm "$GWNM";
        then
                echo "Mask is in valid format"
        else
                echo "Mask is invalid. Halting..."
                exit 1
        fi

	echo $GWIP > single.conf
	echo $GWNM >> single.conf
        
	echo "start deploy topology with one station"
        clean_bridges "$sIP"
	echo "start script on station with single configuration parameter"
	
	scp single.conf root@$sIP:~/NetworkMerger/single.conf
	ssh root@$sIP /root/NetworkMerger/netm_station.sh single.conf
}

function validate_ip() {
	local  ip=$1
	local  stat=1

	if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; 
	then
		OIFS=$IFS
		IFS='.'
		ip=($ip)
		IFS=$OIFS
		[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
		stat=$?
	fi
	return $stat
}

function validate_nm() {
	local stat=1
	
	grep -E -q '^(254|252|248|240|224|192|128)\.0\.0\.0|255\.(254|252|248|240|224|192|128|0)\.0\.0|255\.255\.(254|252|248|240|224|192|128|0)\.0|255\.255\.255\.(254|252|248|240|224|192|128|0)' <<< "$1" && stat=0 || stat=1

	return $stat
}

if [ $# -eq 0 ];
then
	echo "please, input all station's IPs separated by space"
	read -a stations
	SCount=${#stations[@]}
	echo "okay, You have entered $SCount VM's"
	echo "IP validation..."
	
	let wasbad=0
	for (( i=0;i<$SCount;i++ ));
	do
		if validate_ip ${stations[${i}]}; 
		then 
			stat='good' 
		else 
			stat='bad'
			wasbad=1 
		fi
		printf "%-20s: %s\n" "${stations[${i}]}" "$stat"
	done
	if [ $wasbad -eq 1 ];
	then
		echo "One or more IPs is invalid. Halting..."
		exit 1
	fi

	if [ $SCount -eq 1 ];
	then
		single_topo "${stations[0]}"
	fi
	if [ $SCount -eq 2 ];
        then
		echo "two station topology! Cool!"
	fi
	if [ $SCount -ge 3 ];
	then
		echo "oh my gosh, really!?"
	fi
	
else
	echo "Wow! Arguments! I'm not ready yet to be honest."
fi
