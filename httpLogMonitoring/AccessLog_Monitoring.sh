#Module: This script checks Service service http errors and sends email alert.
#
# Date          Author                   Description
# --------      -------------            ------------------------------------------------
# 10/07/19      Ramesh                   Original Version
#
#=============================================================================================

ENV=PRD
HOST=`hostname`
Script_Home=/home/aosbenv/scripts/Service_Monitoring
source ~/scripts/osbprd.env 
timestamp=$(date +%Y-%m-%d-%H-%M)
threshold=3

export LOG_DIR=$ODN_HOME/servers/ohs1/logs/

interval=$(date -d "10 minutes ago" +"%d/%b/%Y %T")

node1_count=`grep "/Service/validateaddress/search" $LOG_DIR/access_log | grep -v 'postcode=.&' | awk ' { print $4 " " $(NF-1)} ' | sed 's/:/ /' | sed 's/\[//' | while IFS= read -r line; do     [[ "$interval" < "$line" ]] && echo "$line"; done | awk ' BEGIN {count=0;}  { if ($3 != "200") count+=1} END {print count}'` #Please change search pattern according to your need.

node2_count=`ssh aosbenv@hostname02 '/home/aosbenv/scripts/Service_Monitoring/Service_Monitoring.sh'`
#echo $node2_count
total_count=$((node1_count + node2_count));
#echo $total_count

if  [ "$total_count" -gt "$threshold" ] ; then
  sendMail='True'
fi

grep "/savs/validateaddress/search" $LOG_DIR/access_log | grep -v 'postcode=.&' | grep -v ' 200 ' | cut -d" " -f 4-10 | sed 's/:/ /' | sed 's/\[//' | while IFS= read -r line; do     [[ "$interval" < "$line" ]] && echo "$line"; done > /home/aosbprd/scripts/SAVS_Monitoring/error_log_Node1.txt

echo -n "Time: " > mail.txt
echo "$(date +%Y-%m-%d-%H-%M)" >> mail.txt
echo "" >> mail.txt
echo "More than $threshold http errors occurred while invoking Service serivce in last 10 mins"  >> mail.txt

echo "------------------  -------- -----------------" >> mail.txt
echo "" >> mail.txt
echo "Number of Errors on Node 1: $node1_count" >> mail.txt
echo "------------------  -------- -----------------" >> mail.txt
echo "" >> mail.txt
cat /home/aosbenv/scripts/Service_Monitoring/error_log_Node1.txt >> mail.txt
echo "" >> mail.txt
echo "------------------  -------- -----------------" >> mail.txt
echo "" >> mail.txt
echo "Number of Errors on Node 2: $node2_count" >> mail.txt
echo "------------------  -------- -----------------" >> mail.txt
echo "" >> mail.txt
ssh aosbenv@hostname02 'cat /home/aosbenv/scripts/Service_Monitoring/error_log.txt' >> mail.txt
echo "" >> mail.txt
echo "------------------  -------- -----------------" >> mail.txt
echo "" >> mail.txt

if [ "$sendMail" == "True" ]
then
echo "Subject: $ENV - $HOST: Service Errors Encountered in Last 10 Mins" | cat - mail.txt | /usr/sbin/sendmail -F "$HOST" "email ids" # Change according to your need.
fi

mv mail.txt $Script_Home/logs/mail_$timestamp.log

find $Script_Home/logs/*.log -mtime +20 -exec rm {} \;

