#!/bin/bash

DATE=$(date +%Y%m%d_%H%M) 


if [ $# -ne 2 ]; then
	echo -e "Give disk name and time [in minutes]";
	exit 1;
fi 

timeout ${2}m "LC_TIME=C iostat -x  1 |stdbuf -o0 grep $1 > /tmp/disk_stats_raw" &
timeout ${2}m "LC_TIME=C sar -r 1 > /tmp/mem_stats_raw" &
timeout ${2}m "LC_TIME=C sar -p 1 > /tmp/cpu_stats_raw"  &

wait

#Format disk,mem,cpu stats to csv
echo "time ; iops ; read[MB] ; write[MB] ; await[s] ; quesize" > /tmp/disk_stats_${DATE}.csv
echo "time ; memtotal ; memfree ; membuff ; memcache" > /tmp/mem_stats_${DATE}.csv 

##########

cat /tmp/disk_stats | awk '{ time=$1 iops=$4+$5 ; read=$6/1024 ; write=$7/1024 ; await=$10 ; quesi=$9 } { print time ";" iops ";" read ";" write ";"  await ";" quesi }' >>  /tmp/disk_stats_${DATE}.csv 
cat /tmp/mem_stats | awk '{ time=$1 memtotal=$2+$3 memfree=$3/1024 ; membuff=$6/1024 ; memcache=$7/1024 } { print time ";" memtotal ";" memfree ";" membuff ";" memcache }' >> /tmp/mem_stats_${DATE}.csv 
cat /tmp/cpu_stats | awk '{ time=$1 usert=$3 ; systemt=$5 ; iowait=$6 } { print time ";" usert ";" systemt ";" iowait }' >> /tmp/cpu_stats_${DATE}.csv 


for i in /tmp/disk_stats_${DATE}.csv /tmp/mem_stats_${DATE}.csv  /tmp/cpu_stats_${DATE}.csv ; do
	sed -i 's/\./\,/g' $i;
done


