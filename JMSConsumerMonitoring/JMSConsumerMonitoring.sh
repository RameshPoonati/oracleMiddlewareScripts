#!/bin/bash
export HOME_DIR=/home/aenvName
source $HOME_DIR/scripts/envName.env
export SCRIPT_HOME=$HOME_DIR/scripts/JMSConsumerMonitoring
cd $SCRIPT_HOME
source $WLS_HOME/server/bin/setWLSEnv.sh

timestamp=$(date +%Y-%m-%d-%H-%M)
java weblogic.WLST $SCRIPT_HOME/JMSConsumerMonitoring.py

mv $SCRIPT_HOME/logs/mail.txt $SCRIPT_HOME/logs/JMSConsumerMonitoring_mail_$timestamp.log
mv $SCRIPT_HOME/logs/log.txt $SCRIPT_HOME/logs/JMSConsumerMonitoring_log_$timestamp.log

find $SCRIPT_HOME/logs/ochConsumerMonitoring_* -mtime +30 -exec rm {} \;
