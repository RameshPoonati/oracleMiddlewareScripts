#Module: This scripts summarizes errors occurred on nodes other than where script is running.
#      
# Date          Author                   Description
# --------      -------------            ------------------------------------------------
# 26/04/22      Ramesh                   Initial Version
#
#=============================================================================================

serverInstance=$1
WL_LOG_DIR=$2

timestamp=$(date +%Y-%m-%d-%H-%M)
logTime=24
logTimeMins=1440

diagTime=`date -d "$logTime hour ago" "+%Y-%m-%dT"`
outTime=`date -d "$logTime hour ago" "+%Y-%m-%d"`
#srvLogTime=`date -d '24 hour ago' "+%b %d, %Y"`
srvLogTime=`date -d "$logTime hour ago" "+%b %e, %Y" | sed 's/  / /'`

#Diagnostic Logs:
find $WL_LOG_DIR  -type f -mmin -"$logTimeMins" -name "$serverInstance-diagnostic*" | xargs grep "\[ERROR\]" | grep "\[$diagTime" | awk -F']' ' { print $NF } ' | sort | uniq -c | awk '$1 = $1 FS "       "' | sed --expression="s/^/$serverInstance-diag   /" > log.txt

#Server out Logs:
find $WL_LOG_DIR  -type f -mmin -"$logTimeMins" -name "$serverInstance.out*" | xargs grep "<Error>" | grep "$srvLogTime" | awk -F'<' ' { print $NF } ' | sort | uniq -c | awk '$1 = $1 FS "       "' | sed --expression="s/^/$serverInstance.out    /" >> log.txt

#Server .logs
find $WL_LOG_DIR  -type f -mmin -"$logTimeMins" -name "$serverInstance.log*" | xargs grep "<Error>" | grep "###<$srvLogTime" |awk -F'<' ' { print $NF } ' | sort | uniq -c | awk '$1 = $1 FS "       "' | sed --expression="s/^/$serverInstance.log    /" >> log.txt

logCount=`cat log.txt | wc -l`

if [ $logCount -gt 0 ]
then
        cat log.txt 
fi

rm log.txt
