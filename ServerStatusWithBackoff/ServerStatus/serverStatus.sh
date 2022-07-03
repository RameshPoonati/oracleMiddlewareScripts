#!/bin/bash
export HOME_DIR=/home/oracle
source $HOME_DIR/scripts/env.properties
export SCRIPT_HOME=$HOME_DIR/scripts/ServerStatus
source $WLS_HOME/server/bin/setWLSEnv.sh

timestamp=$(date +%Y-%m-%d-%H-%M)
java weblogic.WLST $SCRIPT_HOME/serverStatus.py

cp $SCRIPT_HOME/logs/log.txt $SCRIPT_HOME/logs/health_$timestamp.log

find $SCRIPT_HOME/logs/health_* -mtime +30 -exec rm {} \;
