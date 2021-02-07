#!/bin/bash
source /home/oracle/scripts/soaprd.env 
export PATH=$JAVA_HOME/bin:$PATH
export SCRIPT_HOME=/home/oracle/scripts/dataSourceMonitoring
source $WLS_HOME/server/bin/setWLSEnv.sh

timestamp=$(date +%Y-%m-%d-%H-%M)
java weblogic.WLST $SCRIPT_HOME/dsAlert.py

mv $SCRIPT_HOME/logs/log.txt $SCRIPT_HOME/logs/dsAlert_$timestamp.log

find $SCRIPT_HOME/logs/dsAlert_* -mtime +30 -exec rm {} \;

