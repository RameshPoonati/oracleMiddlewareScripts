#Module: This scripts checks the disk usage. 
export SCRIPT_HOME=/home/userName/scripts/DiskCheck
export SCRIPT_LOG=$SCRIPT_HOME/logs

timestamp=$(date +%Y-%m-%d-%H-%M)
ENV=envName
HOST=`hostname`

dfResponse=`timeout 120 df -Pkh` ###Check disk usage. Timeout after 120 secs if there is no response.

echo "########### Disk Space Check ###########" | tee -a mail.dat $SCRIPT_LOG/spaceCheck_$timestamp.log 
echo $dfResponse >>  $SCRIPT_LOG/spaceCheck_$timestamp.log
if [ -z "$dfResponse" ] #Print message if df doesn't give response.
then
	dfNoResponse="True"
	sendMail="True"
	echo "" | tee -a  mail.dat $SCRIPT_LOG/spaceCheck_$timestamp.log
	echo "df command is not responding. Check all mount points." | tee -a  mail.dat $SCRIPT_LOG/spaceCheck_$timestamp.log
fi

if [ `echo "$dfResponse" | grep -ic "stale" ` -gt 0 ] ### Stale file handlers check.
then 
	echo "" >> mail.dat $SCRIPT_LOG/spaceCheck_$timestamp.log
	echo "There are stale file handlers. Please check." | tee -a  mail.dat $SCRIPT_LOG/spaceCheck_$timestamp.log
	sendMail="True"
fi

if [ "$dfNoResponse" != "True" ]
then
	while read line
	do
	mount=$( echo $line | cut -d' ' -f1 )
	threshold=$( echo $line | cut -d' ' -f2 )
	usePercentage=`echo "$dfResponse" | grep -w "$mount$" | awk -F' ' ' { print $5 } ' | sed 's/%$//'`

        if [ "$usePercentage" = "" ]
        then
                echo "" | tee -a mail.dat $SCRIPT_LOG/spaceCheck_$timestamp.log
                echo "$mount is not mounted." | tee -a mail.dat $SCRIPT_LOG/spaceCheck_$timestamp.log
		sendMail="True"

	elif [ $usePercentage -ge $threshold ]
	then
		echo "" | tee -a mail.dat $SCRIPT_LOG/spaceCheck_$timestamp.log
		echo "$mount usage is above the threshold value. Current value is: $usePercentage. Threshold value is $threshold" | tee -a mail.dat $SCRIPT_LOG/spaceCheck_$timestamp.log
		sendMail="True"
	fi
	done < $SCRIPT_HOME/mount.names
fi

echo "" | tee -a mail.dat $SCRIPT_LOG/spaceCheck_$timestamp.log
echo "################## END ##################" | tee -a mail.dat $SCRIPT_LOG/spaceCheck_$timestamp.log

cat $SCRIPT_HOME/instructions.txt >> mail.dat

if [ "$sendMail" = "True" ]
then
mailx -s "Alert: Action Required - $ENV - $HOST - High Disk Usage" -c "$CC" "mailinglist"<mail.dat
fi

rm mail.dat

find $SCRIPT_LOG/spaceCheck_* -mtime +20 -exec rm {} \;

