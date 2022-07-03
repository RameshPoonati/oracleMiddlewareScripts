#Module: This scripts summarizes errors occurred in the previous day.
#      
# Date          Author                   Description
# --------      -------------            ------------------------------------------------
# 21/05/19      Ramesh                   Original Version
#
#=============================================================================================

SCRIPT_HOME=/home/oracle/scripts/ErrorReport
LOGS_DIR=$SCRIPT_HOME/logs
source $SCRIPT_HOME/script.properties
timestamp=$(date +%Y-%m-%d-%H-%M)

logTime=24
logTimeMins=1440
diagTime=`date -d "$logTime hour ago" "+%Y-%m-%dT"`
outTime=`date -d "$logTime hour ago" "+%Y-%m-%d"`
#srvLogTime=`date -d "$logTime hour ago" "+%b %d, %Y"`
srvLogTime=`date -d "$logTime hour ago" "+%b %e, %Y" | sed 's/  / /'`
ohsTime=`date -d "$logTime hour ago" "+%d/%b/%Y"`

#Diagnostic Logs:
find $WL_LOG_DIR  -type f -mmin -"$logTimeMins" -name "$serverInstance-diagnostic*" | xargs grep "\[ERROR\]" | grep "\[$diagTime" | awk -F']' ' { print $NF } ' | sort | uniq -c | awk '$1 = $1 FS "       "' | sed --expression="s/^/$serverInstance-diag   /" > $LOGS_DIR/log.txt

#Server out Logs:
find $WL_LOG_DIR  -type f -mmin -"$logTimeMins" -name "$serverInstance.out*" | xargs grep "Error" | grep "$srvLogTime" | awk -F'<' ' { print $NF } ' | sort | uniq -c | awk '$1 = $1 FS "       "' | sed --expression="s/^/$serverInstance.out    /" >> $LOGS_DIR/log.txt

#Server .logs
find $WL_LOG_DIR  -type f -mmin -"$logTimeMins" -name "$serverInstance.log*" | xargs grep "<Error>" | grep "###<$srvLogTime" |awk -F'<' ' { print $NF } ' | sort | uniq -c | awk '$1 = $1 FS "       "' | sed --expression="s/^/$serverInstance.log    /" >> $LOGS_DIR/log.txt

#OHS access_logs
find $OHS_LOG_DIR  -type f -mmin -"$logTimeMins" -name "access_log*" | xargs grep "$ohsTime" | awk ' $(NF-1) !~ /^2/  && $(NF-1) !~ /^3/ { print "http code: "  $(NF-1) " " $7 " " $8 }' | grep -v "favicon\.ico" | sort | uniq -c | awk '$1 = $1 FS "       "' | sed --expression="s/^/$ohsInstance-access.log      /" >> $LOGS_DIR/log.txt  # Exclude http 200 and 300 series codes

#OHS server.logs
find $OHS_LOG_DIR  -type f -mmin -"$logTimeMins" -name "$ohsInstance.log*" | xargs grep "\[ERROR" | grep "\[$diagTime" | awk -F']' ' { print $NF } ' | sort | uniq -c | awk '$1 = $1 FS "	"' | sed --expression="s/^/$ohsInstance-server.log      /" >> $LOGS_DIR/log.txt

#Loop through remainin nodes
while read serverDetails; do
   server=`echo  $serverDetails | cut -d ',' -f 1`
   serverInstance=`echo  $serverDetails | cut -d ',' -f 2`
   ohsInstance=`echo  $serverDetails | cut -d ',' -f 3`
   WL_LOG_DIR=`echo  $serverDetails | cut -d ',' -f 4`
   OHS_LOG_DIR=`echo  $serverDetails | cut -d ',' -f 5`
   ssh $server "bash -s" < /home/oracle/scripts/ErrorReport/errorReportOther.sh "$serverInstance" "$ohsInstance" "$WL_LOG_DIR" "$OHS_LOG_DIR" >>  $LOGS_DIR/log.txt #Get reports from other nodes.
done < $SCRIPT_HOME/server.list

logCount=`cat $LOGS_DIR/log.txt | wc -l`

if [ $logCount -gt 0 ]
then
	echo "TO:$mailingList"  > $LOGS_DIR/mail.txt
    echo "Subject: $ENV - SOA: Error Report" >>  $LOGS_DIR/mail.txt
	echo "Content-Type: text/html; charset="us-ascii"" >> $LOGS_DIR/mailBody.txt
	echo "<html>" >> $LOGS_DIR/mailBody.txt
	echo "<head><style>body {font-family:courier,serif} table {border-collapse: collapse; width:40% }table, td, th { border: 1px solid black; text-align: left}</style></head>" >> $LOGS_DIR/mailBody.txt
	echo "<body  text="black">" >> $LOGS_DIR/mailBody.txt
	echo "<h4>Following errors noticed in logs in last 24 hrs. </h4>" >> $LOGS_DIR/mailBody.txt
        echo '<table>' >> $LOGS_DIR/mailBody.txt
        echo '<tr><th>Log Name</th><th>Count </th> <th>Error</th></tr>' >> $LOGS_DIR/mailBody.txt
	sort  -k2,2rn -k1,1 $LOGS_DIR/log.txt > $LOGS_DIR/log_sorted.txt
        while read line; 
	do 
	   logFileName=`echo $line | awk ' { print $1 } '`
	   count=`echo $line | awk ' { print $2 } '`
	   errorMessage=`echo $line | awk '{ $1=""; $2=""; print}'`
	   echo "<tr><td>$logFileName</td><td>$count</td><td>$errorMessage</td></tr>" >> $LOGS_DIR/mailBody.txt	   
	done < $LOGS_DIR/log_sorted.txt        
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

mv $LOGS_DIR/log.txt $LOGS_DIR/log_$timestamp.log 2>/dev/null
mv $LOGS_DIR/mailBody.txt $LOGS_DIR/mail_$timestamp.log 2>/dev/null

find $LOGS_DIR/*.log -mtime +20 -exec rm {} \;
