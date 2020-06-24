#!/bin/bash
export HOME_DIR=/home/userName
source $HOME_DIR/scripts/envName.env
export SCRIPT_HOME=$HOME_DIR/scripts/AdapterStatus
source $WLS_HOME/server/bin/setWLSEnv.sh

timestamp=$(date +%Y-%m-%d-%H-%M)
java weblogic.WLST $SCRIPT_HOME/adapterStatus.py

mv $SCRIPT_HOME/logs/log.txt $SCRIPT_HOME/logs/health_$timestamp.log

find $SCRIPT_HOME/logs/health_* -mtime +30 -exec rm {} \;
