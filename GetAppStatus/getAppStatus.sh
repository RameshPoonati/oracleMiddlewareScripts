#!/bin/bash
export HOME_DIR=/home/userName
source $HOME_DIR/scripts/envName.env
export SCRIPT_HOME=$HOME_DIR/scripts/GetAppStatus
cd $SCRIPT_HOME
source $WLS_HOME/server/bin/setWLSEnv.sh

timestamp=$(date +%Y-%m-%d-%H-%M)
java weblogic.WLST $SCRIPT_HOME/getAppStatus.py

mv $SCRIPT_HOME/logs/mail.txt $SCRIPT_HOME/logs/getAppStatus_mail_$timestamp.log

find $SCRIPT_HOME/logs/getAppStatus_* -mtime +30 -exec rm {} \;
