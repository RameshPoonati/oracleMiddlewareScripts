#Description: This script  takes backup of FMW related files.
#      
# Date          Author                   Description
# --------      -------------            ------------------------------------------------
# 11/15/17      Ramesh Poonati           Initial Version
#
#=============================================================================================
#Replace below directories as per your env.
export SCRIPT_HOME=/orabpm/app/scripts/Backup
export LOG_DIR=$SCRIPT_HOME/logs
ENV=QA

export ORACLE_HOME=/orabpm/app/oracle/middleware/
export JAVA_HOME=/orabpm/app/oracle/jdk
export ORACLE_INV=/orabpm/app/oracle/oraInventory
export OSB_DOMAIN_HOME=/orabpm/common/oracle/domains/QA_OSB_domain
export BPM_DOMAIN_HOME=/orabpm/common/oracle/domains/QA_BPM_domain
BACKUP_DIR=/share/ORASQLSHARE/BPMQA/backups
timestamp=$(date +%Y-%m-%d-%H-%M-%S)

TMP_DIR=$SCRIPT_HOME/tmp/Backup_$timestamp
mkdir $TMP_DIR

### Oracle Inventory ###
cd $ORACLE_INV/..
invFileCount=`find $ORACLE_INV | wc -l`
echo "Number of files in inventory directory: $invFileCount" >> $LOG_DIR/backup_$timestamp.log
gtar -zcpf $TMP_DIR/oraInventory_$timestamp.tar.gz oraInventory
invStat=$?
invTarCount=`gtar -ztf $TMP_DIR/oraInventory_$timestamp.tar.gz | wc -l `
echo "Number of files in inventory tar file:  $invTarCount" >> $LOG_DIR/backup_$timestamp.log

### JDK ###
cd $JAVA_HOME/..
jdkFileCount=`find $JAVA_HOME | wc -l`
echo "Number of files in JDK directory: $jdkFileCount" >> $LOG_DIR/backup_$timestamp.log
gtar -zcpf $TMP_DIR/jdk_$timestamp.tar.gz jdk
jdkStat=$?
jdkTarCount=`gtar -ztf $TMP_DIR/jdk_$timestamp.tar.gz | wc -l`
echo "Number of files in JDK tar file: $jdkTarCount" >> $LOG_DIR/backup_$timestamp.log

### ORACLE_HOME ###
cd $ORACLE_HOME/..
orahomeFileCount=`find $ORACLE_HOME | wc -l`
echo "Number of files in ORACLE HOME directory: $orahomeFileCount" >> $LOG_DIR/backup_$timestamp.log
gtar -zcpf $TMP_DIR/orahome_$timestamp.tar.gz middleware
orahomeStat=$?
orahomeTarCount=`gtar -ztf $TMP_DIR/orahome_$timestamp.tar.gz | wc -l`
echo "Number of files in ORACLE_HOME tar file: $orahomeTarCount" >> $LOG_DIR/backup_$timestamp.log

### OSB DOMAIN_HOME ###
cd $OSB_DOMAIN_HOME/..
OSB_domainhomeFileCount=`find $OSB_DOMAIN_HOME | wc -l`
echo "Number of files in OSB DOMAIN HOME directory: $OSB_domainhomeFileCount" >> $LOG_DIR/backup_$timestamp.log
gtar -zcpf $TMP_DIR/OSB_domain_$timestamp.tar.gz --exclude 'servers/*/data/store/default/_WLS_*.DAT' --exclude '*FileStore*/*.DAT' QA_OSB_domain
OSB_domainStat=$?
OSB_domainTarCount=`gtar -ztf $TMP_DIR/OSB_domain_$timestamp.tar.gz | wc -l`
echo "Number of files in OSB_DOMAIN_HOME tar file:  $OSB_domainTarCount" >> $LOG_DIR/backup_$timestamp.log

### BPM DOMAIN_HOME ###
cd $BPM_DOMAIN_HOME/..
bpm_domainhomeFileCount=`find $BPM_DOMAIN_HOME | wc -l`
echo "Number of files in BPM DOMAIN HOME directory: $bpm_domainhomeFileCount" >> $LOG_DIR/backup_$timestamp.log
gtar -zcpf $TMP_DIR/bpm_domain_$timestamp.tar.gz --exclude 'servers/*/data/store/default/_WLS_*.DAT' --exclude '*FileStore*/*.DAT' QA_BPM_domain
bpm_domainStat=$?
bpm_domainTarCount=`gtar -ztf $TMP_DIR/bpm_domain_$timestamp.tar.gz | wc -l`
echo "Number of files in BPM DOMAIN_HOME tar file:  $bpm_domainTarCount" >> $LOG_DIR/backup_$timestamp.log

#echo "$invStat  $jdkStat $orahomeStat $domainStat" >> $LOG_DIR/backup_$timestamp.log
cd $TMP_DIR/..
gtar -zcpf ${ENV}_backup_$timestamp.tar.gz Backup_$timestamp
bkFileSize=`du -h ${ENV}_backup_$timestamp.tar.gz | awk -F' ' ' { print $1 }'`
mv ${ENV}_backup_$timestamp.tar.gz  $BACKUP_DIR
copyStat=$?

echo "$invStat  $jdkStat $orahomeStat $OSB_domainStat $bpm_domainStat $copyStat" >> $LOG_DIR/backup_$timestamp.log

mailing_list="Space separated email ids"

if [[ ($invStat -eq 0 || $invStat -eq 1)&& ($jdkStat -eq 0 || $jdkStat -eq 1) && ($orahomeStat -eq 0 || $orahomeStat -eq 1) && ($OSB_domainStat -eq 0 || $OSB_domainStat -eq 1) && ($bpm_domainStat -eq 0 || $bpm_domainStat -eq 1) && $copyStat -eq 0 ]]
then
	echo "Export is successful !!! Backup file size is: $bkFileSize" >> $LOG_DIR/backup_$timestamp.log
	echo "Backup job completed successfully. Backup file size is: $bkFileSize" | mailx -s "$ENV - Backup Successful" $mailing_list
else
	echo "Export failed !!!" >> $LOG_DIR/backup_$timestamp.log
	echo "Backup job failed." | mailx -s "$ENV - Backup Failed" $mailing_list
fi

rm -r $TMP_DIR
find $BACKUP_DIR/${ENV}_backup_*  -mtime +15 -exec rm {} \;
find $LOG_DIR/backup_*  -mtime +365 -exec rm {} \;
