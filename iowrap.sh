#!/bin/bash

DATE=$(date +%Y%m%d_%H%M)
#sar 24h format.
export LC_TIME=C

#Provide disk name and how long the monitor is going to work - in minutes
if [ $# -ne 2 ]; then
        echo -e "Type disk name[like sda] and monitoring time[in minutes]";
        exit 1;
fi

#Run tasks parallely in bg
timeout ${2}m iostat -x  1 |stdbuf -o0 grep $1 > $HOME/disk_stats_raw &
timeout ${2}m sar -r 1 > $HOME/mem_stats_raw &
timeout ${2}m sar -p 1 > $HOME/cpu_stats_raw  &

wait

#Format disk,mem,cpu stats to csv
echo "iops ; read[MB] ; write[MB] ; await ; quesize" > $HOME/disk_stats_nottime
echo "time ; memtotal ; memfree ; membuff/cache" > $HOME/mem_stats_${DATE}.csv
echo "time ; %user ; %system ; %iowait" > $HOME/cpu_stats_${DATE}.csv

#sar in 1st column shows time, iostat doesn't
tail -n +4 $HOME/disk_stats_raw | awk '{ iops=$4+$5 ; read=$6/1024 ; write=$7/1024 ; await=$10 ; quesi=$9 } { print iops ";" read ";" write ";"  await ";" quesi }' >>  $HOME/disk_stats_nottime
tail -n +4 $HOME/mem_stats_raw | awk '{ time=$1 ; memtotal=($2+$3)/1024 ; memfree=$2/1024 ; membuffcache=($5+$6)/1024 } { print time ";" memtotal ";" memfree ";" membuffcache }' >> $HOME/mem_stats_${DATE}.csv
tail -n +4 $HOME/cpu_stats_raw | awk '{ time=$1 ; usert=$3 ; systemt=$5 ; iowait=$6 } { print time ";" usert ";" systemt ";" iowait }' >> $HOME/cpu_stats_${DATE}.csv

#get time from another file
cat $HOME/mem_stats_${DATE}.csv | awk -F ';' '{ print $1 }' > $HOME/time

#fetch time and disk stats
paste -d ';' $HOME/time $HOME/disk_stats_nottime > $HOME/disk_stats_${DATE}.csv

#delete unused files
rm -f $HOME/time $HOME/disk_stats_nottime

#change '.' to ','
for i in $HOME/disk_stats_${DATE}.csv $HOME/mem_stats_${DATE}.csv  $HOME/cpu_stats_${DATE}.csv ; do
        sed -i 's/\./\,/g' $i;
done