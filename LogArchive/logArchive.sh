#Module: This scripts zips and archives log files.
#
# Date          Author                   Description
# --------      -------------            ------------------------------------------------
# 20/09/19      Ramesh                   Original Version
#
#=============================================================================================
export SCRIPT_HOME=~/scripts/LogArchive
export SCRIPT_LOG=$SCRIPT_HOME/logs

timestamp=$(date +%Y-%m-%d-%H-%M)
retentionDays=15

suffix=`echo "_$(date +%Y-%m-%d-%H-%M).gz"`
archivePeriod=180 #Files older than this value in mins will be archived.

logLocation=`cat $SCRIPT_HOME/logArchive.par | grep log.location | cut -d'=' -f2`
serverLogName=`cat $SCRIPT_HOME/logArchive.par | grep server.log | cut -d'=' -f2`
outLogName=`cat $SCRIPT_HOME/logArchive.par | grep server.out | cut -d'=' -f2`
diagLogName=`cat $SCRIPT_HOME/logArchive.par | grep server.diag | cut -d'=' -f2`

cd $logLocation

echo "Archiving Files ..." >> $SCRIPT_LOG/logArchive_$timestamp
find .  -maxdepth 1 -mmin +$archivePeriod  -type f \( -name "$diagLogName-[0-9]*" -o -name "$outLogName[0-9]*" -o -name "$serverLogName[0-9]*" \) | xargs gzip -v -S $suffix 2>&1 | tee  -a $SCRIPT_LOG/logArchive_$timestamp

echo "" >> $SCRIPT_LOG/logArchive_$timestamp
echo "Moving compressed files to archive directory ... " >> $SCRIPT_LOG/logArchive_$timestamp

mv *$suffix log_archives

oldFileCount=`find log_archives/*.gz -mtime +$retentionDays | wc -l`

echo "" >> $SCRIPT_LOG/logArchive_$timestamp
echo "There are $oldFileCount files older than $retentionDays. " >> $SCRIPT_LOG/logArchive_$timestamp
echo "Deleting old files ..." >> $SCRIPT_LOG/logArchive_$timestamp

find log_archives/*.gz -mtime +$retentionDays -exec rm {} \; # Deletes old archive files.
find $SCRIPT_LOG/logArchive_* -mtime +30 -exec rm {} \;      # Deletes old log files.

