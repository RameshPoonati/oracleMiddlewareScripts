#!/bin/bash
#Module: This script extracts logs written for a given time period. 
#      
# Date          Author                   Description
# --------      -------------            ------------------------------------------------
# 19/03/21      Rameshi Poonati          Initial Version
#
#========================================================================================
SCRIPT_HOME=/home/oracle/scripts/LogExtractor
source $SCRIPT_HOME/extract.properties
mkdir -p $LOGS_DIR

rm -rf $SCRIPT_HOME/tmp/*

function getInput()
{
	echo ""
	echo "You can use this utility to extract logs by either:" 
	echo ""
	echo "                   Option 1: Duration in mins"
	echo "                   Option 2: Period (e.g., `date --date '-10 min' '+%Y-%m-%d %H:%M'` to `date '+%Y-%m-%d %H:%M'`)"
	echo ""

	re1="^[0-9]+$"
	re2="^[2][0-9]{3}\-([0][1-9]|[1][012])\-([0][1-9]|[12][0-9]|3[01])([[:space:]])([01][0-9]|2[0123])\:([0-5][0-9])$"
	while  [[ "$durationOrPeriod" -ne 1 ]] && [[ "$durationOrPeriod" -ne 2 ]]; do
		read -p 'Enter 1 for Duration or 2 for Period: ' durationOrPeriod
		echo ""
		if [[ "$durationOrPeriod" == 1 ]]; then 
			while ! [[ "$extractMins" =~ $re1 ]]; do
				read -p 'Enter value for last mins: ' extractMins 
			done
		elif [[ "$durationOrPeriod" == 2 ]]; then
			while ! [[ "$startTime" =~ $re2 ]]; do
				read -p 'Enter start time in YYYY-MM-DD-HH24:MI format: ' startTime
			done 
			while ! [[ "$endTime" =~ $re2 ]]; do
				read -p 'Enter end  time in  YYYY-MM-DD-HH24:MI format: ' endTime
			done 
		fi
	done
	echo ""

	logLevel=0
	while  [[ "$logLevel" -lt 1 ]] || [[ "$logLevel" -gt 4 ]]; do
		read -p 'Enter log level to be extracted. 1 - Error, 2 - Warning, 3 - Notification, 4 - ALL: ' logLevel
	done
	echo ""
}

function convertMins2Period()
{
	mins=$1
	if [[ "$durationOrPeriod" == 1 ]]; then
		endTimeEpoch=`date +%s`
   		startTimeEpoch=`expr $endTimeEpoch - 60 \* $mins`
		echo "Logs will extracted between: `date -d @$startTimeEpoch` and `date -d @$endTimeEpoch`"
   	elif [[ "$durationOrPeriod" == 2 ]]; then
		startTimeEpoch=`date -d "$startTime" +"%s"`
#		echo "startTimeEpoch: $startTimeEpoch"
		endTimeEpoch=`date -d "$endTime" +"%s"`
   	fi
}

function constructDiagSearchString()
{	
	if [[ "$logLevel" == 1 ]]; then
		diagSearchString="ERROR\]"
		serverLogSearchString="<Alert>|<Critical>|<Error>"
		ohsSearchString="\[ERROR"
   	elif [[ "$logLevel" == 2 ]]; then
		diagSearchString="ERROR\]|\[WARNING\]"
		serverLogSearchString="<Alert>|<Critical>|<Error>|<Warning>"
		ohsSearchString="\[ERROR|\[NOTIFICATION"
   	elif [[ "$logLevel" == 3 ]]; then
        	diagSearchString="ERROR\]|\[WARNING\]|\[NOTIFICATION"
		serverLogSearchString="<Alert>|<Critical>|<Error>|<Warning>|<Notice>"
		ohsSearchString="\[ERROR|\[NOTIFICATION"
   	elif  [[ "$logLevel" == "4" ]]; then
		diagSearchString="^\["
		serverLogSearchString="^####<|^<"
		ohsSearchString=".+"
   	fi
}

function getLogFiles()
{
	allFileList=`find $WL_LOG_DIR $OHS_LOG_DIR -maxdepth 1 -type f -name "$1*" -printf '%T@ %p\n' | sort`
	count=`echo "$allFileList" | wc -l`
	declare -A fileData
	i=0
	while IFS= read -r line; do
        	i=$((i + 1))
        	fileData[$i,1]=$i
        	fileData[$i,2]=$line
	done <<< "$allFileList"

	startFileFound="False"
	endFileFound="False"
	for ((i=1;i<=$count;i++)) do
        	fileTime=`awk ' { print $1 } ' <<< "${fileData[$i,2]}"`
        	if [[ "$startFileFound" == "False" && $fileTime > $startTimeEpoch ]] ; then
                	startFileFound="True"
                	startIndex=$i
        	fi
        	if [[ "$endFileFound" == "False" && $fileTime > $endTimeEpoch ]] ; then
                	endFileFound="True"
                	endIndex=$i
        	fi
	done

	if [[ "$startFileFound" == "True" && "$endFileFound" == "False" ]] ; then #This statement handles if file with end time not present in list of files.
		endIndex=$i
	fi
	j=0
	declare -A returnFiles
#	echo $startIndex
#	echo "endIndex: $endIndex"
	if [[ $startIndex > 0 && $endIndex > 0 ]] ; then
		for ((i=$startIndex;i<=$endIndex;i++)) do
			j=$((j + 1))
			returnFiles[$j]=`awk ' { print $2 }'  <<< ${fileData[$i,2]}`
		done
	fi
	echo "${returnFiles[*]}"
}

getInput # Call getInput function.
convertMins2Period "$extractMins"
constructDiagSearchString

#Get list of files modified in specified time.
if [[ "$durationOrPeriod" == 1 ]]; then
	find $WL_LOG_DIR  $ARCH_WL_LOG_DIR $OHS_LOG_DIR -maxdepth 1 -type f -mmin -"$mins" \( -name "$serverInstance-diagnostic*" -o -name "$serverInstance.log*" -o -name "$serverInstance.out*" -o -name "access.log*"  -o -name "access_log*"  -o -name "$ohsInstance.log*" \) -exec cp -p {} $SCRIPT_HOME/tmp \; 2>/dev/null
elif [[ "$durationOrPeriod" == 2 ]]; then
	declare -a logFileDirs=("$WL_LOG_DIR:$serverInstance-diagnostic" "$WL_LOG_DIR:$serverInstance.out" "$WL_LOG_DIR:$serverInstance.log" "$WL_LOG_DIR:access.log" "$OHS_LOG_DIR:access_log" "$OHS_LOG_DIR:$ohsInstance.log") 
        for logFileDir in "${logFileDirs[@]}"
	do
	        logDir=`awk -F':' ' { print $1 } ' <<< $logFileDir`
	        logFile=`awk -F':' ' { print $2 } ' <<< $logFileDir`
#		echo "logDir: $logDir"
#		echo "logFile: $logFile"
		files="$(getLogFiles "$logFile" "$logDir")"
	#	echo "files: $files"
		cp  --preserve $files $SCRIPT_HOME/tmp 2>/dev/null
	done
fi
awk '/^\[.*\]/{if (x)print x;x="";}{x=(!x)?$0:x"MEDELIMT"$0;}END{print x;}' $SCRIPT_HOME/tmp/"$serverInstance-diagnostic"*  > $SCRIPT_HOME/tmp/"diag.mod" #Concatenate lines without timestamp to get stacktrace at later stage.

awk '/^####</{if (x)print x;x="";}{x=(!x)?$0:x"MEDELIMT"$0;}END{print x;}' $SCRIPT_HOME/tmp/"$serverInstance.log"*  > $SCRIPT_HOME/tmp/"log.mod" #Concatenate lines without timestamp to get stacktrace at later stage.

awk '/^<.*[0-9]{4}\s[0-9]{1,2}[:][0-9]{2}[:][0-9]{2}.*>/{if (x)print x;x="";}{x=(!x)?$0:x"MEDELIMT"$0;}END{print x;}' $SCRIPT_HOME/tmp/"$serverInstance.out"*  > $SCRIPT_HOME/tmp/"out.mod" #Concatenate lines without timestamp to get stacktrace at later stage.
ls -rt $SCRIPT_HOME/tmp/"access.log"* 2>/dev/null | xargs cat > $SCRIPT_HOME/tmp/"ServerAccess.mod" #Concatenate server access log files.
ls -rt $SCRIPT_HOME/tmp/"access_log"* 2>/dev/null | xargs cat > $SCRIPT_HOME/tmp/"OHSAccess.mod" #Concatenate OHS access log files.
ls -rt $SCRIPT_HOME/tmp/"$ohsInstance.log"* 2>/dev/null | xargs cat > $SCRIPT_HOME/tmp/"ohsLog.mod" #Concatenate OHS server log files.

#echo "Start of diag read: `date`"
#<< 'MULTILINE-COMMENT'
echo "Reading Server Diagnostic Logs ..."
while IFS= read -r line #Processng diagnostic logs
    do
	 recordTime=$(sed -n "s/^\[\([0-9]\{4\}\-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\).*$/\1/p" <<< $line)
	 epochRecordTime=`date -d $recordTime +"%s"`
	 if [[ "$epochRecordTime" -ge "$startTimeEpoch" && "$epochRecordTime" -lt "$endTimeEpoch" ]] ; then
	    echo "$line" | egrep "$diagSearchString"  >>  $LOGS_DIR/Extract_ServerDiagnostics.log
	   # echo "$line"   >>  $LOGS_DIR/Extract_Diagnostics_log.txt
	 fi 
done < "$SCRIPT_HOME/tmp/diag.mod" 
#echo "End of diag read: `date`"
#echo "Start of log read: `date`"

while IFS= read -r line
    do
	 recordTime=`awk -F'[<>]' ' { print $2 } ' <<< "$line" | sed 's/,[0-9]\{1,3\}//g' | sed 's/,//g'`
	 epochRecordTime=`date -d "$recordTime" +"%s"`
	 if [[ "$epochRecordTime" -ge "$startTimeEpoch" && "$epochRecordTime" -lt "$endTimeEpoch" ]] ; then	
	    echo "$line" | egrep "$serverLogSearchString"  >>  $LOGS_DIR/Extract_ServerLog.log
	 fi 
done < "$SCRIPT_HOME/tmp/log.mod" 
#echo "End of log read: `date`"
#echo "Start of out read: `date`"
echo "Reading Server Out Logs ..."
while IFS= read -r line
    do
	recordTime=`awk -F'[<>]' ' { print $2 } ' <<< "$line" | sed 's/,[0-9]\{1,3\}//g' | sed 's/,//g'`
	#echo $line
        epochRecordTime=`date -d "$recordTime" +"%s"`
	if [[ "$epochRecordTime" -ge "$startTimeEpoch" && "$epochRecordTime" -lt "$endTimeEpoch" ]] ; then	
	    echo "$line" | egrep "$serverLogSearchString"  >>  $LOGS_DIR/Extract_ServerOut.log
	fi 
done < "$SCRIPT_HOME/tmp/out.mod"
#echo "End of out read: `date`"
#echo "Start of server access read: `date`"
re3="^[23][0-9]{2}$"

echo "Reading Server Access Logs ..."
while IFS= read -r line
    do
	recordTime=`awk ' { print $1 " " $2 } ' <<< "$line"`
        epochRecordTime=`date -d "$recordTime" +"%s" 2>/dev/null`
	httpResCode=`awk ' { print $(NF-2) } ' <<< "$line"` #Gets http response code. Change field number according to you log.
        if [[ "$httpResCode" =~ $re3 ]] ; then
		httpSuccess="True"
	else
		httpSuccess="False"
	fi 
	if [[ "$epochRecordTime" -ge "$startTimeEpoch" && "$epochRecordTime" -lt "$endTimeEpoch" ]] ; then
		if [[ "$logLevel" != 1 || "$httpSuccess" != "True" ]] ; then
	   		echo "$line"  >>  $LOGS_DIR/Extract_ServerAccess.log
		fi
	fi 
done < "$SCRIPT_HOME/tmp/ServerAccess.mod"
#MULTILINE-COMMENT
#echo "End of server access read: `date`"
#echo "Start of  ohs server read: `date`"
echo "Reading OHS Logs ..."
while IFS= read -r line
    do
	 recordTime=$(sed -n "s/^\[\([0-9]\{4\}\-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\).*$/\1/p" <<< "$line")
	 epochRecordTime=`date -d $recordTime +"%s"`
	 if [[ "$epochRecordTime" -ge "$startTimeEpoch" && "$epochRecordTime" -lt "$endTimeEpoch" ]] ; then
	    #echo $line | egrep "$diagSearchString"  >>  $LOGS_DIR/Extract_Diagnostics_log.txt
	    echo "$line" | egrep "$ohsSearchString" >> $LOGS_DIR/Extract_OHSLog.log
	 fi 
done < "$SCRIPT_HOME/tmp/ohsLog.mod"
 
#echo "End of ohs log read: `date`"
#echo "Start of  ohs access read: `date`"
echo "Reading OHS Access Logs ..."
while IFS= read -r line
    do
	recordTime=`awk -F'[][]' ' { print $2 } ' <<< "$line" | awk ' { print $1 } ' | sed 's/\//-/g' | awk -F':' ' { print $1 " " $2 ":" $3 } ' `
        epochRecordTime=`date -d "$recordTime" +"%s"`
	#echo "recordTime: $recordTime"
	#echo "epochRecordTime: $epochRecordTime"
	httpResCode=`awk ' { print $(NF-1) } ' <<< "$line"` #Gets http response code. Change field number according to you log.
        if [[ "$httpResCode" =~ $re3 ]] ; then
		httpSuccess="True"
	else
		httpSuccess="False"
	fi 
	#if [[ "$epochRecordTime" > "$startTimeEpoch" && "$epochRecordTime" < "$endTimeEpoch" ]] ; then
	if [[ "$epochRecordTime" -ge "$startTimeEpoch" && "$epochRecordTime" -lt "$endTimeEpoch" ]] ; then
		if [[ "$logLevel" != 1 || "$httpSuccess" != "True" ]] ; then
	   		echo "$line"  >>  $LOGS_DIR/Extract_OHSAccess.log
		fi
	fi 
done < "$SCRIPT_HOME/tmp/OHSAccess.mod"
#echo "End of OHS access read: `date`"
sed -i 's/MEDELIMT/\n/g' $LOGS_DIR/*
#mv $LOGS_DIR/log.txt $LOGS_DIR/Extract_$timestamp.log

