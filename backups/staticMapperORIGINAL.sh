#!/bin/bash
###                                   TEST ON R-PI!!!
#### ThiS WILL ONLY MAP STATIC IPS!!! 
rm -f dhcpdEDITING.conf
touch dhcpdEDITING.conf
function hostEntry () {
	echo -e "host $1 {\\tfixed-address $3 ; \\thardware ethernet $2 ; } ## $TODAY"
}
function addip () {
	hostEntry $NEWHOST $NEWMACLC $OLDIP >> dhcpdEDITING.conf
#	if dhcpd -t -cf /etc/dhcp/dhcpdEDITING.conf ; then
#		sleep 3
	#	cp /etc/dhcp/dhcpdEDITING.conf /etc/dhcp/dhcpd.conf
#		sudo systemctl restart isc-dhcp-server
#		systemctl status isc-dhcp-server
#	else
#		echo "THERE WERE ERRORS IN YOUR CONFIG, EXITING."
		#cp /etc/dhcp/dhcpdCOPY.conf /etc/dhcp/dhcpd.conf
#		exit
#	fi
}
function macFromIp () {
ping -c 1 -w 0.2 $1 1&>2 2>/dev/null
arp -a $1 | awk '{print $4}'      # PASS THIS FUNCTION AN IP ADDRESS AND IT RETURNS MAC 
}

# nested-loop.sh: Nested "for" loops
total=0
for rack in {1..9}; # NUMBER OF RACKS TO LOOP THRU
do
  #echo "---------------------"
  for shelf in {1..5};  # NUMBER OF SHELVES TO LOOP THRU
  do
    for column in {1..5}    # NUMBER OF COLUMNS TO LOOP THRU
	do
	
	if [ "$shelf" -eq 5 ] && [ "$column" -gt 4 ]  # Excludes 3 and 11.
	then
		continue      # Skip rest of this particular loop iteration.
 	fi
		
		let "total+=1"        #  RIGHT HERE GOTTA CALL MY IP SET FUNCTION AND GRAB MAC
		echo "rack:$rack miner:$shelf-$column and total=$total"
		ipVar="10.$rack.$shelf.$column.$total"
		echo "ip:$ipVar"
	done

  done
	echo "---------------------"
done               

