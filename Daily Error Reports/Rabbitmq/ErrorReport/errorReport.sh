#Module: This scripts summarizes errors occurred in the previous day.
#      
# Date          Author                   Description
# --------      -------------            ------------------------------------------------
# 21/05/19      Ramesh                   Original Version
#
#=============================================================================================

SCRIPT_HOME=/home/rmquser/scripts/ErrorReport
LOGS_DIR=$SCRIPT_HOME/logs
source $SCRIPT_HOME/script.properties
timestamp=$(date +%Y-%m-%d-%H-%M)

logTime=24
logTimeMins=1440
searchTime=`date -d "$logTime hour ago" "+%Y-%m-%d"`

rm -rf $SCRIPT_HOME/tmp/*
#RMQ Rabbit Logs:
find $RMQ_LOG_DIR  -type f -mmin -"$logTimeMins" -name "rabbit\.log*" -exec cp {} $SCRIPT_HOME/tmp \;
awk '/[0-9]{4}-[0-9]{2}-[0-9]{2}/{if (x)print x;x="";}{x=(!x)?$0:x"MEDELIMT"$0;}END{print x;}' $SCRIPT_HOME/tmp/* > $LOGS_DIR/singleLog.txt #Concatenate logs spread over multiple lines.

#Sed is used to remove ip pairs. Otherwise almost every record in the log will be unique with ip port combination.
grep "\[error\]" $LOGS_DIR/singleLog.txt | sed 's/MEDELIMT//g' | grep "$searchTime" | sed 's/ <[0-9]*\.[0-9]*\.[0-9]*>//g' | sed 's/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}.*[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:[1-9]\{1,5\}//g'| awk -F'error]' ' { print $NF } ' |   sort | uniq -c | sed --expression="s/^/$RMQ_NODE.log   /" > $LOGS_DIR/log.txt

#Loop through remainin nodes
while read serverDetails; do
   server=`echo  $serverDetails | cut -d ',' -f 1`
   RMQ_NODE=`echo  $serverDetails | cut -d ',' -f 2`
   RMQ_LOG_DIR=`echo  $serverDetails | cut -d ',' -f 3`
   ssh $server "bash -s" < $SCRIPT_HOME/errorReportOther.sh "$RMQ_NODE" "$RMQ_LOG_DIR" >>  $LOGS_DIR/log.txt #Get reports from other nodes.
done < $SCRIPT_HOME/server.list
logCount=`cat $LOGS_DIR/log.txt | wc -l`

if [ $logCount -gt 0 ]
then
	sort  -k2,2rn -k1,1 $LOGS_DIR/log.txt > $LOGS_DIR/log_sorted.txt
        head -1000 $LOGS_DIR/log_sorted.txt > $LOGS_DIR/log_top.txt
	echo "TO:$mailingList"  > $LOGS_DIR/mail.txt
        echo "Subject: $ENV - RMQ: Error Report" >>  $LOGS_DIR/mail.txt
	echo "Content-Type: text/html; charset="us-ascii"" > $LOGS_DIR/mailBody.txt
	echo "<html>" >> $LOGS_DIR/mailBody.txt
	echo "<head><style>body {font-family:courier,serif} table {border-collapse: collapse; width:40% }table, td, th { border: 1px solid black; text-align: left}</style></head>" >> $LOGS_DIR/mailBody.txt
	echo "<body  text="black">" >> $LOGS_DIR/mailBody.txt
	echo "<h4>Following errors noticed in logs in last 24 hrs. </h4>" >> $LOGS_DIR/mailBody.txt
        echo '<table>' >> $LOGS_DIR/mailBody.txt
        echo '<tr><th>Log Name</th><th>Count </th> <th>Error</th></tr>' >> $LOGS_DIR/mailBody.txt
        while read line; 
	do 
	   logFileName=`echo $line | awk ' { print $1 } '`
	   count=`echo $line | awk ' { print $2 } '`
	   errorMessage=`echo $line | awk '{ $1=""; $2=""; print}'`
	   echo "<tr><td>$logFileName</td><td>$count</td><td>$errorMessage</td></tr>" >> $LOGS_DIR/mailBody.txt
	done < $LOGS_DIR/log_top.txt
        echo "</table>" >> $LOGS_DIR/mailBody.txt
	echo "" >> $LOGS_DIR/mailBody.txt
	echo "<br>" >> $LOGS_DIR/mailBody.txt
        echo "</body>" >> $LOGS_DIR/mailBody.txt
        echo "</html>" >> $LOGS_DIR/mailBody.txt
        cat $LOGS_DIR/mailBody.txt  >> $LOGS_DIR/mail.txt
        echo "" >> $LOGS_DIR/mail.txt
        echo "" >> $LOGS_DIR/mail.txt
        cat $LOGS_DIR/mail.txt | /usr/sbin/sendmail -t
fi

rm $LOGS_DIR/singleLog.txt $LOGS_DIR/log_top.txt
mv $LOGS_DIR/log.txt $LOGS_DIR/log_$timestamp.log 2>/dev/null
mv $LOGS_DIR/mailBody.txt $LOGS_DIR/mail_$timestamp.log 2>/dev/null

find $LOGS_DIR/*.log -mtime +20 -exec rm {} \;
