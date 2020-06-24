#Module: This scripts summarizes errors occurred in past 60 mins. 
#      
# Date          Author                   Description
# --------      -------------            ------------------------------------------------
# 21/05/19      Ramesh                   Original Version
#
#=============================================================================================

ENV=envName
HOST=`hostname`
Script_Home=/home/userName/scripts/ErrorReport
timestamp=$(date +%Y-%m-%d-%H-%M)

export LOG_DIR=/u03/app/oracle/envName/admin/osb_domain/mserver/osb_domain/servers/osb_server1/logs

diagTime=`date -d '1 hour ago' "+%Y-%m-%dT%H"`
outTime=`date -d '1 hour ago' "+%d-%b-%Y %H"`

#Diagnostic Logs:

 find $LOG_DIR  -type f -mmin -60 -name "osb_server1-diagnostic*" | xargs grep "\[ERROR\]" | grep "\[$diagTime" | awk -F']' ' { print $NF } ' | sort | uniq -c | sed --expression='s/^/osb_server1-diag /' > log.txt

#Server out Logs:

 find $LOG_DIR  -type f -mmin -60 -name "osb_server1.out*" | xargs grep "<Error>" | grep "<$outTime" |awk -F'<' ' { print $NF } ' | sort | uniq -c | sed --expression='s/^/osb_server1.out /' >> log.txt

#Server .logs
 find $LOG_DIR  -type f -mmin -60 -name "osb_server1.log*" | xargs grep "<Error>" | grep "###<$outTime" |awk -F'<' ' { print $NF } ' | sort | uniq -c | sed --expression='s/^/osb_server1.log /'>> log.txt

ssh userName@cem4sosbaprd02 '/home/userName/scripts/ErrorReport/errorReport.sh' >>  log.txt
echo -n "Time: " > mail.txt
echo "$(date +%Y-%m-%d-%H-%M)" >> mail.txt
echo "" >> mail.txt
echo "Following Errors are noticed in logs:"  >> mail.txt

echo "------------------  -------- -----------------" >> mail.txt
echo "Log Name            Count    Error" >> mail.txt
echo "------------------  -------- -----------------" >> mail.txt
echo "" >> mail.txt

sort -nrk 2,2  log.txt >> mail.txt

echo "" >> mail.txt
logCount=`cat log.txt | wc -l`


if [ $logCount -gt 0 ] 
then
echo "  "
echo "Subject: $ENV - $HOST: Error Report" | cat - mail.txt | /usr/sbin/sendmail -F "$HOST" "youremailid"
fi

mv log.txt $Script_Home/Logs/log_$timestamp.log
mv mail.txt $Script_Home/Logs/mail_$timestamp.log

find $Script_Home/Logs/*.log -mtime +20 -exec rm {} \;
