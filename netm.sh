#!/bin/bash

exec 1> >(logger -s -t $(basename $0)) 2>&1

declare -a GWNM

function clean_bridges {
        if (validate_ip $1 = 0) && (connectivity $1 = 0);
	then
		ssh root@$1 'for BR in $(ovs-vsctl list-br); do ovs-vsctl del-br $BR; done'
		return 0
	else
		echo "IP $1 is invalid or inaccessible"
		return 1
	fi
}

function connectivity() {
	ping -c 1 $1 2>&1 > /dev/null
	return $?
}

function get_ip_and_netmask_from_user {
	echo "please, specify the bridge IP which should be default gateway for hosts in $1"
        echo "IP: "
        read GWIP
        echo "Mask: "
        read NM

        if validate_ip "$GWIP";
        then
                echo "ip is ok"
        else
                echo "ip is invalid. Halting..."
                return 1
        fi

        if validate_nm "$NM";
        then
                echo "mask is ok"
        else
                echo "Mask is invalid. Halting..."
                return 1
        fi
	GWNM[0]=${GWIP}
	GWNM[1]=${NM}
}

function single_topo {
        sIP=$1
	
	get_ip_and_netmask_from_user "both networks"
	echo ${GWNM[0]} > single.conf
	echo ${GWNM[1]} >> single.conf
	echo "file single.conf writed"
        
	echo "---- start deploy topology with one station ----"
	echo "start cleaning on $sIP ..."
        clean_bridges "$sIP"
	echo "sending config file to $sIP"
	scp single.conf root@$sIP:~/NetworkMerger/single.conf
	echo "sending complete"
	echo "start script on station with single configuration parameter"
	ssh root@$sIP /root/NetworkMerger/netm_station.sh single.conf
}

function double_topo {
	S1=$1
	S2=$2
	
	if get_ip_and_netmask_from_user "first network"
	then
        	echo ${GWNM[0]} > double1.conf
        	echo ${GWNM[1]} >> double1.conf
	else
		exit 1
	fi
	
	if get_ip_and_netmask_from_user "second network"
	then
        	echo ${GWNM[0]} > double2.conf
        	echo ${GWNM[1]} >> double2.conf
	else
		exit 1
	fi
	
	echo $S2 >> double1.conf
	echo $S1 >> double2.conf

	echo "---- start deploy topology with two stations ----"
        echo "start cleaning on $S1 ..."
        clean_bridges "$S1"
        echo "start cleaning on $S2 ..."
        clean_bridges "$S2"

	echo "sending config file to $S1"
        scp double1.conf root@$S1:/root/NetworkMerger/double.conf
        echo "sending complete"
	
	echo "sending config file to $S2"
        scp double2.conf root@$S2:/root/NetworkMerger/double.conf
        echo "sending complete"

        echo "start script on $S1 with double configuration parameter"
        ssh root@$S1 /root/NetworkMerger/netm_station.sh double.conf

	echo "start script on $S2 with double configuration parameter"
        ssh root@$S2 /root/NetworkMerger/netm_station.sh double.conf
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

function send_script {
	scp netm_station.sh root@$1:/root/NetworkMerger/netm_station.sh
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
	echo "IP and connectivity validation..."
	
	let wasbad=0
	for (( i=0;i<$SCount;i++ ));
	do
		if (validate_ip ${stations[${i}]} = 0) && (connectivity ${stations[${i}]} = 0);
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
		echo "One or more IPs is invalid or unpingable. Halting..."
		exit 1
	fi

	echo "re-send script to stations? (y/n)"
	while true; 
	do
    		read yn
    		case $yn in
        		[Yy]* ) for (( i=0;i<$SCount;i++ )); do send_script ${stations[${i}]}; done; break;;
        		[Nn]* ) break;;
        		* ) echo "Please answer yes or no.";;
    		esac
	done 

	if [ $SCount -eq 1 ];
	then
		single_topo "${stations[0]}"
	fi
	if [ $SCount -eq 2 ];
        then
		double_topo ${stations[0]} ${stations[1]}
	fi
	if [ $SCount -ge 3 ];
	then
		echo "oh my gosh, really!?"
	fi
	
else
	if [[ $1 = "clear" && $# -ge 2 ]]
	then
		args=("$@")
		for (( i=1;i<$#;i++ ));
		do
			if (clean_bridges ${args[${i}]} = 0) then echo "${args[${i}]} cleared"; fi;
		done
	fi
fi
