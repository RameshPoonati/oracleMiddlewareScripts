#Module: This scripts summarizes errors occurred in past 60 mins. 
#      
# Date          Author                   Description
# --------      -------------            ------------------------------------------------
# 21/05/19      Ramesh                   Original Version
#
#=============================================================================================

ENV=QA
SCRIPT_HOME=/home/oracle/scripts/ErrorReport
LOGS_DIR=$SCRIPT_HOME/logs
timestamp=$(date +%Y-%m-%d-%H-%M)

serverInstance=WLS_SOA1
ohsInstance=OHS_1
ohsPrintName=ohs1 #Print name is used for easier understanding in mails. Instance names used in this installation are not suer friendly.
WL_LOG_DIR=/oracle/config/mserver/domains/soa_domain/servers/$serverInstance/logs
OHS_LOG_DIR=/oracle/config/mserver/domains/soa_domain/servers/$ohsInstance/logs

#This script can be converted to daily report by removing Hour from below varialbes.
diagTime=`date -d '1 hour ago' "+%Y-%m-%dT%H"`
outTime=`date -d '1 hour ago' "+%Y-%m-%d %H"`
srvLogTime=`date -d '1 hour ago' "+%b %d, %Y %-H"`
ohsTime=`date -d '1 hour ago' "+%d/%b/%Y:%H"`

#Diagnostic Logs:
find $WL_LOG_DIR  -type f -mmin -60 -name "$serverInstance-diagnostic*" | xargs grep "\[ERROR\]" | grep "\[$diagTime" | awk -F']' ' { print $NF } ' | sort | uniq -c | awk '$1 = $1 FS "       "' | sed --expression="s/^/$serverInstance-diag   /" > $LOGS_DIR/log.txt

#Server out Logs:
find $WL_LOG_DIR  -type f -mmin -60 -name "$serverInstance.out*" | xargs grep "ERROR" | grep "$outTime" | awk -F'<' ' { print $NF } ' | sort | uniq -c | awk '$1 = $1 FS "       "' | sed --expression="s/^/$serverInstance.out    /" >> $LOGS_DIR/log.txt

#Server .logs
find $WL_LOG_DIR  -type f -mmin -60 -name "$serverInstance.log*" | xargs grep "<Error>" | grep "###<$srvLogTime" |awk -F'<' ' { print $NF } ' | sort | uniq -c | awk '$1 = $1 FS "       "' | sed --expression="s/^/$serverInstance.log    /" >> $LOGS_DIR/log.txt

#OHS access_logs
find $OHS_LOG_DIR  -type f -mmin -60 -name "access_log*" | xargs grep "$ohsTime" | awk ' $(NF-1) !~ /^2/  && $(NF-1) !~ /^3/ { print "http code: "  $(NF-1) " " $7 " " $8 }' | grep -v "favicon\.ico" | sort | uniq -c | awk '$1 = $1 FS "       "' | sed --expression="s/^/$ohsPrintName-access.log      /" >> $LOGS_DIR/log.txt  # Exclude http 200 and 300 series codes

#OHS server.logs
find $OHS_LOG_DIR  -type f -mmin -60 -name "$ohsInstance.log*" | xargs grep "\[ERROR" | grep "\[$diagTime" | awk -F'>' ' { print $NF } ' | sort | uniq -c | awk '$1 = $1 FS "	"' | sed --expression="s/^/$ohsPrintName-server.log      /" >> $LOGS_DIR/log.txt

ssh oracle@orasoa-test50-w2 '/home/oracle/scripts/ErrorReport/errorReport.sh' >>  $LOGS_DIR/log.txt #Get reports from other nodes.

logCount=`cat $LOGS_DIR/log.txt | wc -l`

if [ $logCount -gt 0 ]
then
	
	echo "TO:ramesh@sharespoint.com "  > $LOGS_DIR/mail.txt
    echo "Subject: $ENV - SOA: Error Report" >>  $LOGS_DIR/mail.txt

	echo -n "Time: " > $LOGS_DIR/mailBody.txt
	echo "$(date +%Y-%m-%d-%H-%M)" >> $LOGS_DIR/mailBody.txt
	echo "" >> $LOGS_DIR/mailBody.txt
	echo "Following Errors are noticed in logs:"  >> $LOGS_DIR/mailBody.txt
	echo "------------------     --------   -----------------" >> $LOGS_DIR/mailBody.txt
	echo "Log Name            Count      Error" >> $LOGS_DIR/mailBody.txt
	echo "------------------     --------   -----------------" >> $LOGS_DIR/mailBody.txt
	echo "" >> $LOGS_DIR/mailBody.txt

	sort  -k1,1 -k2,2rn $LOGS_DIR/log.txt >> $LOGS_DIR/mailBody.txt
	echo "" >> $LOGS_DIR/mailBody.txt
        cat $LOGS_DIR/mailBody.txt  >> $LOGS_DIR/mail.txt
        echo "" >> $LOGS_DIR/mail.txt
        echo "" >> $LOGS_DIR/mail.txt
        cat $LOGS_DIR/mail.txt | /usr/sbin/sendmail -t
fi

mv $LOGS_DIR/log.txt $LOGS_DIR/log_$timestamp.log 2>/dev/null
mv $LOGS_DIR/mailBody.txt $LOGS_DIR/mail_$timestamp.log 2>/dev/null

find $LOGS_DIR/*.log -mtime +20 -exec rm {} \;
