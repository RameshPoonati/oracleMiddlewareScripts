#/bin/sh 
echo "start" 
logtime=$(date +%Y-%m-%d-%H-%M)
script_dir=/home/aprdsob/scripts/ThreadDump
count=0 
while [ $count -lt 5 ] 
do 
count=`expr $count + 1` 
echo $count 
 
jstack 27282  >> $script_dir/logs/threadDump_$logtime.txt
sleep 10
done 

echo "end" 
