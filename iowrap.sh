#!/bin/bash

#LC_TIME=C
DATE=$(date +%Y%m%d_%H%M) 


if [ $# -ne 2 ]; then
	echo -e "Give disk name and time [in minutes]";
	exit 1;
fi 

timeout ${2}m iostat -x  1 |stdbuf -o0 grep $1 > /tmp/disk_stats_raw &
timeout ${2}m sar -r 1 > /tmp/mem_stats_raw & 
timeout ${2}m sar -p 1 > /tmp/cpu_stats_raw &

wait

#Format disk,mem,cpu stats to csv
cat /tmp/disk_stats | awk '{ iops=$4+$5 ; read=$6/1024 ; write=$7/1024 ; await=$10 ; quesi=$9 } { print iops ";" read ";" write ";"  await ";" quesi }' >  /tmp/disk_stats_${DATE}.csv 
cat /tmp/mem_stats | awk '{ memfree=$3/1024 ; membuff=$6/1024 ; memcache=$7/1024 } { print memfree ";" membuff ";" memcache }' > /tmp/mem_stats_${DATE}.csv 
cat /tmp/cpu_stats | awk '{ usert=$4 ; systemt=$6 ; iowait=$7 } { print usert ";" systemt ";" iowait }' > /tmp/cpu_stats_${DATE}.csv 


for i in /tmp/disk_stats_${DATE}.csv /tmp/mem_stats_${DATE}.csv  /tmp/cpu_stats_${DATE}.csv ; do
	sed -i 's/\./\,/g' $i;
done


#echo "CSV files with statistics" | mutt -s "$(hostname) performance stats"  -a /tmp/${1}_stats_${DATE}.csv -a /tmp//mem_stats_${DATE}.csv -a /tmp/cpu_stats_${DATE}.csv -- piotr.gacek@alior.pl
