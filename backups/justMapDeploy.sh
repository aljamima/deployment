#!/bin/bash
#    start script by scanning subnet into list1.txt prompt user to plug in first miner
#  scan network again until you find a new ip. 
function pause() {
 read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
}
function hostEntry () {
	echo -e "host $1 {\\tfixed-address $3; \\thardware ethernet $2; } $TODAY" >> dhcpEDITING.conf
}
function macFromIp () {			 # PASS THIS FUNCTION AN IP ADDRESS AND IT RETURNS MAC 
ping -c 1 -w 0.2 $1              # ping it first to make sure its in our arp table
arp -a $1 | awk '{print $4}'     
}


### do i need dhcp shit here???



export SSHPASS='admin'
rm -f dhcpEDITING.conf 2>/dev/null
touch dhcpEDITING.conf
echo "PLEASE UNPLUG ALL DEVICES OTHER THAN THIS DEPLOYMENT MACHINE"
pause
fping -a -g 192.168.0.1 192.168.0.254 2>/dev/null  > out1.txt   # first scan to find ips we want to exclude from search 
total=0
container=3

for rack in {1..9}; # of racks to loop thru ex: start..end
do
  rackTotal=0
  for shelf in {1..5};  # of shelves on the rack  ex: 1..5 means shelves start at 1 and go up to 5
  do
    for column in {1..4}    # NUMBER OF slots on the shelf. 
	do
		let "rackTotal+=1"
		let "total+=1"     
		if [ "$shelf" -eq 5 ] && [ "$column" -gt 4 ]  #this means it wont do any miners past shelf 5 - position 4. so only 24 rigs that rack
		then
			continue      # Skip rest of this particular loop iteration if its higher than number 24
	 	fi
		position="$container-$rack-$shelf-$column" # 1-1-1-1
		ipVar="10.$container.$rack.$rackTotal" # 10.x.x.x
		mask="255.0.0.0"		
		echo "Scanning Network, Please Wait"
		echo "Ready To Map $ipVar to $position, please plug in device and"
		pause # call my pause function and wait for user
		echo "Looking For New Device..."
		fping -a -g 192.168.0.1 192.168.0.254 2>/dev/null > out2.txt
		foundIp=$(diff <(sort out1.txt) <(sort out2.txt))    # have it sort here instead of piping scans thru sort
		foundIp2=$(echo $foundIp | head -n1 | awk '{print $1;}') # this is just checking to make sure theres only 1 IP returned from function
		mac=$(./macFromIp.sh $foundIp2)
		hostEntry $position $mac $ipVar
		echo "Miner was $foundIp, changing to $ipVar"
		echo $foundIp2 >> out1.txt
		genMap="curl 'https://app.genesis-hive.com/scripts.php?id=createRigs' -H 'Origin: https://app.genesis-hive.com' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.9,es-419;q=0.8,es;q=0.7,ru;q=0.6' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Safari/537.36' -H 'content-type: application/x-www-form-urlencoded; charset=UTF-8' -H 'Accept: */*' -H 'Referer: https://app.genesis-hive.com/new.php/deployRigs' -H 'Cookie: PHPSESSID=lgdvemhtsrl33hb0v2v10ihtl4; apiKey=8a5f18ad8a4c75a19089eab75ec10d0d' -H 'Connection: keep-alive' --data 'rowNr[]=$container&shelfNr[]=$rack&levelNr[]=$shelf&indexNr[]=$column&mac[]=$mac&minerTypeId[]=104&cardsPerMiner[]=4&area[]=GrowMine&levelsPerShelf=null&minersPerLevel=null&newFarmId=45' --compressed"
#       curl 'https://app.genesis-hive.com/scripts.php?id=createRigs' -H 'Origin: https://app.genesis-hive.com' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.9,es-419;q=0.8,es;q=0.7,ru;q=0.6' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Safari/537.36' -H 'content-type: application/x-www-form-urlencoded; charset=UTF-8' -H 'Accept: */*' -H 'Referer: https://app.genesis-hive.com/new.php/deployRigs' -H 'Cookie: PHPSESSID=hlrcps1j81sj1844i9d9ki8555; apiKey=8a5f18ad8a4c75a19089eab75ec10d0d' -H 'Connection: keep-alive' --data 'rowNr[]=3&shelfNr[]=1&levelNr[]=1&indexNr[]=1&mac[]=68:9E:19:A7:95:9E&minerTypeId[]=104&cardsPerMiner[]=4&area[]=GrowMine&levelsPerShelf=null&minersPerLevel=null&newFarmId=45' --compressed
		eval $(echo $genMap)
	done
  done
done    		
	
