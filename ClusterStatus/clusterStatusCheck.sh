#!/bin/bash
#Description: This script checks status of atom.
#      
# Date          Author                   Description
# --------      -------------            ------------------------------------------------
# 06/12/22      Ramesh Poonati           Initial Version
#
#=============================================================================================
SCRIPT_HOME=/home/boomi/scripts/ClusterStatus #Change according to your env.
SCRIPT_LOG=$SCRIPT_HOME/logs

timestamp=$(date +%Y-%m-%d-%H-%M)
HOST=`hostname`

while read parameters; do
  case "$parameters" in \#*) continue ;; esac ## To skip comments. Ref: https://stackoverflow.com/questions/12488556/bash-loop-skip-commented-lines

  IFS=';' read -ra paraArray <<< "$parameters"
  env=${paraArray[0]}
  hosts=${paraArray[1]}
  bin_location=${paraArray[2]}
  first_node=`echo $hosts | awk -F',' '{ print $1 }'`
  ips=''
  for host in ${hosts//,/ }
  do
    ip=`host $host | awk ' { print $NF } '`
    ascii_ip=`echo "${ip//./_}"`
    ips+=$ascii_ip
    ips+=','
  done
  echo "connecting to $host"
  timeout 30 ssh $host "bash -s" < $SCRIPT_HOME/remoteScript.sh "$env" "$ips" "$bin_location" >>  $SCRIPT_LOG/cluster_status.log_$timestamp
  return_code=$?
  if [ "$return_code" -gt 1 ]
  then
    echo "[$timestamp] Not able to ssh and execute script in $host VM in $env." >> $SCRIPT_LOG/cluster_status.log_$timestamp 
    echo "" >> $SCRIPT_LOG/cluster_status.log_$timestamp
  fi
done < $SCRIPT_HOME/envs.properties

log_count=`cat $SCRIPT_LOG/cluster_status.log_$timestamp | wc -l`
echo "log_count: $log_count"

if [ "$log_count" -gt 0  ]; then
	TOLIST="abc@xyz.com,alice@xyz.com"
	echo "Subject: Attention !!! - Boomi Atom Health Check Alert" >  $SCRIPT_LOG/mail.html
	echo "TO: $TOLIST" >> $SCRIPT_LOG/mail.html
        echo "One more atoms are down. Please check." >> $SCRIPT_LOG/mail.html
        echo "" >> $SCRIPT_LOG/mail.html
        cat $SCRIPT_LOG/cluster_status.log_$timestamp>> $SCRIPT_LOG/mail.html
        echo "" >> $SCRIPT_LOG/mail.html
	/usr/sbin/sendmail -t -F "$HOST" < $SCRIPT_LOG/mail.html
        rm $SCRIPT_LOG/mail.html
fi
find $SCRIPT_LOG/cluster_status.log_$timestamp -mtime +15 -exec rm {} \;
