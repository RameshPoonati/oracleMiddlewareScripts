#!/bin/bash
export WL_HOME=/orabpm/app/oracle/middleware/wlserver
export JAVA_HOME=/orabpm/app/oracle/jdk1.8.0_60
export PATH=$JAVA_HOME/bin:$PATH
export SCRIPT_HOME=/orabpm/app/scripts/dataSourceMonitoring
source $WL_HOME/server/bin/setWLSEnv.sh

timestamp=$(date +%Y-%m-%d-%H-%M)
java weblogic.WLST $SCRIPT_HOME/dsAlert.py

mv $SCRIPT_HOME/logs/log.txt $SCRIPT_HOME/logs/dsAlert_$timestamp.log

find $SCRIPT_HOME/logs/dsAlert_* -mtime +30 -exec rm {} \;

