#============================================================================
# This Script Monitors JMS bridges and sends alert if any bridge is inactive.
#
#=============================================================================

export SCRIPT_HOME=/home/userName/scripts/JMSBridges
export SCRIPT_LOG=$SCRIPT_HOME/logs

timestamp=$(date +%Y-%m-%d-%H-%M)
ENV=OnPrem_envName
HOST=`hostname`

admpasswd=
admURL=hostname:port
domain=domainName
source $SCRIPT_HOME/../envName.env
source $WL_HOME/server/bin/setWLSEnv.sh
retryCount=3
retrySleep=30

for server in `grep srvr_target  $SCRIPT_HOME/bridge.properties| cut -d'=' -f2` 
do
 for bridge in `grep JMS_bridge  $SCRIPT_HOME/bridge.properties| cut -d'=' -f2`
 do
	bridgeStatus=''
	i=0
  	while [ $i -lt $retryCount ] && [ "$bridgeStatus" != "Active" ] # Recheck if bridge is inactive.
	do	
		bridgeDetails=`java weblogic.Admin -url t3://$admURL -username weblogic -password $admpasswd GET -pretty -type MessagingBridgeRuntime -mbean $domain:ServerRuntime=$server,Name=$bridge,Type=MessagingBridgeRuntime,Location=$server -property Description -property Name -property State | grep -v MBeanName`
 		echo $bridgeDetails
 		bridgeStatus=`echo $bridgeDetails | awk ' { print $8 }' `	
		i=$((i+1))

		if [ "$bridgeStatus" !=  "Active" ]
	        then
			echo "Sleeping for  $retrySleep seconds..." >>  $SCRIPT_LOG/bridgeStatus_$timestamp.log
			sleep $retrySleep	
		fi
	done

 	if [ "$bridgeStatus" !=  "Active" ]
 	then
		sendMail="True"
		echo "" | tee -a  $SCRIPT_LOG/mail.dat $SCRIPT_LOG/bridgeStatus_$timestamp.log
		echo "Bridge $bridge is Inactive in server $server " | tee -a  $SCRIPT_LOG/mail.dat $SCRIPT_LOG/bridgeStatus_$timestamp.log
	else
		echo "" | tee -a  $SCRIPT_LOG/mail.dat $SCRIPT_LOG/bridgeStatus_$timestamp.log
		echo "Bridge $bridge is active in server $server" | tee -a   $SCRIPT_LOG/bridgeStatus_$timestamp.log
 	fi
 done
done

if [ "$sendMail" = "True" ]
then
sed -i '1s/^/Following JMS bridges are down or servers are not reachable:\n/' $SCRIPT_LOG/mail.dat
cat $SCRIPT_HOME/instructions.txt >> $SCRIPT_LOG/mail.dat
mailx -s "Alert: Action Required - $ENV - JMS Bridge(s) is Down" -c "$CC" "mailing list"<$SCRIPT_LOG/mail.dat

fi
rm $SCRIPT_LOG/mail.dat

find $SCRIPT_LOG/bridgeStatus_* -mtime +30 -exec rm {} \;
