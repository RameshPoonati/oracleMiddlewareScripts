#Module: This script checks Service service http errors and sends email alert.
#
# Date          Author                   Description
# --------      -------------            ------------------------------------------------
# 10/07/19      Ramesh Poonati           Original Version
#
#=============================================================================================

ENV=PRD
HOST=`hostname`
Script_Home=/home/ayour/scripts/Service_Monitoring
source scripts/your.env
timestamp=$(date +%Y-%m-%d-%H-%M)

export LOG_DIR=$ODN_HOME/servers/ohs2/logs

interval=$(date -d "12 minutes ago" +"%d/%b/%Y %T")

count=`grep "/Service/validateaddress/search" $LOG_DIR/access_log | grep -v 'postcode=.&' | awk ' { print $4 " " $(NF-1)} ' | sed 's/:/ /' | sed 's/\[//' | while IFS= read -r line; do     [[ "$interval" < "$line" ]] && echo "$line"; done | awk ' BEGIN {count=0;}  { if ($3 != "200") count+=1} END {print count}'`

grep "/Service/validateaddress/search" $LOG_DIR/access_log | grep -v 'postcode=.&' | grep -v ' 200 ' | cut -d" " -f 4-10 | sed 's/:/ /' | sed 's/\[//' | while IFS= read -r line; do     [[ "$interval" < "$line" ]] && echo "$line"; done > /home/ayour/scripts/Service_Monitoring/error_log.txt

echo $count
