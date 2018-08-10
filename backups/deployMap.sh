#!/bin/bash
###                                   TEST ON R-PI!!!
#### ThiS WILL ONLY MAP STATIC IPS!!! 
#
#    start script by scanning subnet into list1.txt prompt user to plug in first miner
#  scan network again until you find a new ip. ssh into it and set ifconfig 10.1.1.1 eth0
#  ifconfig eth0 10.1.1.1 netmask 255.0.0.0
#
#
export SSHPASS='admin'
rm -f dhcpEDITING.conf 2>/dev/null
touch dhcpEDITING.conf
function pause(){
 read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
}
function hostEntry () {
	echo -e "host $1 {\\tfixed-address $3 ; \\thardware ethernet $newMac $TODAY" >> dhcpEDITING.conf
}
function grab_Hashrates_Genesis {
#	for server in $1; do
	server=$1
	position=$2
	mac=$3
	apistats=`echo -n "summary+gpucount" | nc -w 1 $server 4028 2>/dev/null`
	HASHRATE=`echo $apistats | sed -e 's/,/\n/g' | grep "MHS av" | cut -s -d "=" -f2`
	GPUCOUNT=`echo $apistats | sed -e 's/,/\n/g' | grep "Count" | cut -d "=" -f2`
	POOLS=`echo $apiStats | sed -e 's/,/\n/g' | grep "URL" | cut -d "=" -f2`
	TYPE=`echo $apiStats | sed -e 's/,/\n/g' | grep "Description" | cut -d "=" -f2`
	BLADECOUNT=`echo $apiStats | sed -e 's/,/\n/g' | grep "miner_count=" | cut -d "=" -f2`
	gHASHRATE=$(bc -l <<< "$HASHRATE/1000")
	hashes=$(echo $gHASHRATE | head -c 4)
	mType="GPU_Miner"
	zeros="0"
	ninety="90"
	if [[ $(echo "$HASHRATE > $ninety" | bc -l) -eq 0 ]]; then
# min=$(echo 12.45 10.35 | awk '{if ($1 < $2) print $1; else print $2}')
		LOW="HASHRATE IS LOW"
	else
		LOW=""
	fi
#	echo "$server is $mType at: $HASHRATE GH/s and $GPUCOUNT Gpus $LOW" >> hashratesGenesis.txt
	hostEntry $position $mac $server 
	beginString="curl 'http://localhost:3000/employees/save' -H 'Origin: http://localhost:3000' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.9,es-419;q=0.8,es;q=0.7,ru;q=0.6' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Safari/537.36' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8' -H 'Cache-Control: max-age=0' -H 'Referer: http://localhost/employees/create' -H 'Connection: keep-alive' --data 'name=$server&mac=$mac&type=$mType&position=$position&hashrate=$HASHRATE' --compressed"
	eval $(echo $beginString)
#	done
}
function grab_Hashrates_Mgt {
#	for server in $1; do
	server=$1
	position=$2
	mac=$3
	apistats=`echo -n "stats" | nc -w 1 $server 4028 2>/dev/null`
	HASHRATE=`echo $apistats | sed -e 's/,/\n/g' | grep "GHS av" | cut -d "=" -f2`
	BLADECOUNT=`echo $apistats | sed -e 's/,/\n/g' | grep "miner_count=" | cut -d "=" -f2`
	POOLS=`echo $apiStats | sed -e 's/,/\n/g' | grep "URL" | cut -d "=" -f2`
	TYPE=`echo $apiStats | sed -e 's/,/\n/g' | grep "Description" | cut -d "=" -f2`
	mType="S9_Miner"
#	gHASHRATE=$(bc -l <<< "$HASHRATE/1000")
#	hashes=$(echo $gHASHRATE | head -c 4)
	if [[ "$BLADECOUNT" -lt "3" ]]; then
		LOW="LOW HASHRATE -- 1 OR MORE CARDS DOWN"
	else
		LOW=""
	fi
#	echo "$server is $mType at: $hashes TH/s with $BLADECOUNT cards mining $LOW" >> hashratesMgt.txt
	hostEntry $position $mac $server
	beginString="curl 'http://localhost:3000/employees/save' -H 'Origin: http://localhost:3000' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.9,es-419;q=0.8,es;q=0.7,ru;q=0.6' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Safari/537.36' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8' -H 'Cache-Control: max-age=0' -H 'Referer: http://localhost:3000/employees/create' -H 'Connection: keep-alive' --data 'name=$server&mac=$mac&type=$mType&position=$position&hashrate=$HASHRATE' --compressed"
	eval $(echo $beginString)
#	done
}
function macFromIp () {
ping -c 1 -w 0.2 $1
arp -a $1 | awk '{print $4}'      # PASS THIS FUNCTION AN IP ADDRESS AND IT RETURNS MAC 
}
function postData () {
posVar=$2
mac=$3
APISTATS=`echo -n "pools" | nc -w 1 $1 4028`
DESCR=`echo $APISTATS | sed -e 's/,/\n/g' | grep "Description" | cut -d "=" -f2`
BM="bm"
SG="sg"
if [[ $DESCR = $BM* ]]; then
	grab_Hashrates_Mgt $1 $posVar $mac
elif [[ $DESCR = $SG* ]]; then 
	grab_Hashrates_Genesis $1 $posVar $mac
else
	### FOR NOW call it genesis, BUT WE SHOULD MAKE ANOTHER FUNCTION FOR NONMINERS OR MINER TYPES THAT SOFTWARE DOESNT RECOGNZE YET.
	echo "$checks is NOT a miner" >> notMiner.txt
	grab_Hashrates_Genesis $1 $posVar $mac
fi
}
fping -a -g 192.168.100.1 192.168.100.254 2>/dev/null | sort > out1.txt   # first scan to find ips we want to exclude from search 
#fing -a -g 10.2.1.1/22 2>/dev/null | sort > out1.txt   # first scan to find ips we want to exclude from search 
# nested-loop.sh: Nested "for" loops
total=0
container=1
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
	#	zmap -p 22 -i eth1 10.1.1.1/11 -o zmapOutput | sort -a
		echo "Scanning Network, Please Wait"

		echo "Ready To Map $ipVar to $position"
	#	echo "Please Press SpaceBar Once You Have Plugged In $position"
		pause
		echo "Looking For New Device..."
		fping -a -g 192.168.100.1 192.168.100.254 2>/dev/null | sort > out2.txt
#	fping -a -g 10.2.1.1/22 2>/dev/null | sort > out2.txt
		foundIp=$(diff <(sort out1.txt) <(sort out2.txt))
	#try somethin else...	foundIp=$(diff out1.txt out2.txt | grep -E '>*' | awk -F\> '{ print $2 }' | awk -F\< '{ print $1 }' | sed '/^\s*$/d')
		foundIp2=$(echo $foundIp | head -n1 | awk '{print $1;}')
		mac=$(macFromIp $foundIp2)
		postData $ipVar $position $mac
		echo "Miner was $foundIp, changing to $ipVar"
		echo $foundIp2 >> out1.txt
 	    sshpass -e ssh -o StrictHostKeyChecking=no root@$foundIp2 /sbin/ifconfig eth0 $ipVar netmask $mask && service networking restart
	#	pause
	done
  done
done    		
	
