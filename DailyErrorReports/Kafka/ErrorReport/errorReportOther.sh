#Module: This scripts summarizes errors occurred on nodes other than where script is running.
#      
# Date          Author                   Description
# --------      -------------            ------------------------------------------------
# 26/04/22      Ramesh                   Initial Version
#
#=============================================================================================

KAFKA_NODE=$1
KAFKA_LOG_DIR=$2

logTime=24
logTimeMins=1440
searchTime=`date -d "$logTime hour ago" "+%Y-%m-%d "`

#Kafka Logs:
find $KAFKA_LOG_DIR  -type f -mmin -"$logTimeMins" -name "server\.log\.*" | xargs grep " ERROR " | grep "$searchTime" | awk -F' ERROR ' ' { print $2 } ' |   sort | uniq -c | sed --expression="s/^/$KAFKA_NODE.log   /" > log.txt


logCount=`cat log.txt | wc -l`

if [ $logCount -gt 0 ]
then
        cat log.txt
fi

rm log.txt
