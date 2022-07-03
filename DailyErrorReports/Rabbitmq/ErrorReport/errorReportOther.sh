#Module: This scripts summarizes errors occurred on nodes other than where script is running.
#      
# Date          Author                   Description
# --------      -------------            ------------------------------------------------
# 26/04/22      Ramesh                   Initial Version
#
#=============================================================================================

RMQ_NODE=$1
RMQ_LOG_DIR=$2

timestamp=$(date +%Y-%m-%d-%H-%M)

logTime=24
logTimeMins=1440
searchTime=`date -d "$logTime hour ago" "+%Y-%m-%d"`

rm -rf tmp/* 2>/dev/null
mkdir tmp 2>/dev/null
#RMQ Rabbit Logs:
find $RMQ_LOG_DIR  -type f -mmin -"$logTimeMins" -name "rabbit\.log*" -exec cp {} tmp \;
awk '/[0-9]{4}-[0-9]{2}-[0-9]{2}/{if (x)print x;x="";}{x=(!x)?$0:x"MEDELIMT"$0;}END{print x;}' tmp/* > singleLog.txt #Concatenate logs spread over multiple lines.

#Sed is used to remove ip pairs. Otherwise almost every record in the log will be unique with ip port combination.
grep "\[error\]" singleLog.txt | sed 's/MEDELIMT//g' | grep "$searchTime" | sed 's/ <[0-9]*\.[0-9]*\.[0-9]*>//g' | sed 's/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}.*[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:[1-9]\{1,5\}//g'| awk -F'error]' ' { print $NF } ' |   sort | uniq -c | sed --expression="s/^/$RMQ_NODE.log   /" > log.txt

logCount=`cat log.txt | wc -l`

if [ $logCount -gt 0 ]
then
        cat log.txt
fi

rm log.txt singleLog.txt
