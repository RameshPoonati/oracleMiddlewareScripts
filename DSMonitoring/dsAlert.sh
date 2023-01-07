#!/bin/bash
source /home/oracle/scripts/osbdev.env #change according to your env. sample file is provided for reference.
export PATH=$JAVA_HOME/bin:$PATH
export SCRIPT_HOME=/home/oracle/scripts/DSMonitoring
source $WLS_HOME/server/bin/setWLSEnv.sh

timestamp=$(date +%Y-%m-%d-%H-%M)
java weblogic.WLST $SCRIPT_HOME/dsAlert.py $SCRIPT_HOME/script.properties

mv $SCRIPT_HOME/logs/log.txt $SCRIPT_HOME/logs/dsAlert_$timestamp.log
mv $SCRIPT_HOME/logs/error.txt $SCRIPT_HOME/logs/dsAlert_error_$timestamp.log

find $SCRIPT_HOME/logs/dsAlert_* -mtime +30 -exec rm {} \;
