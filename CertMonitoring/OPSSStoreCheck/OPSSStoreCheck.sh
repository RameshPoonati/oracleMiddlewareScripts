#This shell wrapper script to invoke wlst. Please make changes below env variables.
env=DEVSOA 
export HOME_DIR=/home/oracle
source $HOME_DIR/scripts/dev.env #This file contains MW_HOME, JAVA HOME etc. Sample file is available in script dir.
export SCRIPT_HOME=$HOME_DIR/scripts/OPSSStoreCheck
export SCRIPT_LOG=$SCRIPT_HOME/logs
source $WLS_HOME/server/bin/setWLSEnv.sh
timestamp=$(date +%Y-%m-%d-%H-%M)

cd $SCRIPT_HOME
java weblogic.WLST $SCRIPT_HOME/OPSSStoreCheck.py

num_certs_expiring=`wc -l $SCRIPT_LOG/cert.log | cut -d ' ' -f 1`
alertDays=`cat $SCRIPT_HOME/config.properties | grep "alertDays" | cut -d '=' -f 2`

if [ $num_certs_expiring -gt 0 ]
then
        recipients=`cat $SCRIPT_HOME/config.properties | grep "email_ids" | cut -d'=' -f 2` #Get email ids of alert recipients.
        echo "TO: $recipients" > $SCRIPT_LOG/mail.txt
        echo "Subject: Warning !!! $env KSS Certificate Expiry Alert" >>  $SCRIPT_LOG/mail.txt
        echo "Below KSS certificate(s) are expiring in $alertDays days:" >> $SCRIPT_LOG/mail.txt
        echo "" >> $SCRIPT_LOG/mail.txt
        cat $SCRIPT_LOG/cert.log >> $SCRIPT_LOG/mail.txt
        echo "" >> $SCRIPT_LOG/mail.txt
        cat $SCRIPT_HOME/logs/mail.txt | /usr/sbin/sendmail -t
fi

mv $SCRIPT_LOG/cert.log $SCRIPT_LOG/expiringCert_$timestamp.log

find $SCRIPT_LOG/expiringCert_* -mtime +30 -exec rm {} \;
rm $SCRIPT_LOG/expiringCerts.txt
