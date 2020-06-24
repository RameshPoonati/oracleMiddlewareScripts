#!/bin/bash
export HOME_DIR=/home/aenvName
source $HOME_DIR/scripts/envName.env
export SCRIPT_HOME=$HOME_DIR/scripts/QueueMonitoring
cd $SCRIPT_HOME
source $WLS_HOME/server/bin/setWLSEnv.sh

timestamp=$(date +%Y-%m-%d-%H-%M)
java weblogic.WLST $SCRIPT_HOME/QueueMonitoring.py

mv $SCRIPT_HOME/logs/mail.txt $SCRIPT_HOME/logs/QueueMonitoring_mail_$timestamp.log
mv $SCRIPT_HOME/logs/log.txt $SCRIPT_HOME/logs/QueueMonitoring_log_$timestamp.log

find $SCRIPT_HOME/logs/QueueMonitoring_* -mtime +30 -exec rm {} \;
