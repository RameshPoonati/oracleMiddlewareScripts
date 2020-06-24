#!/bin/bash
export HOME_DIR=/home/aosbpre
source $HOME_DIR/scripts/osbpre.env
export SCRIPT_HOME=$HOME_DIR/scripts/ThreadMon
source $WLS_HOME/server/bin/setWLSEnv.sh

timestamp=$(date +%Y-%m-%d-%H-%M)
java weblogic.WLST $SCRIPT_HOME/threadMon.py

mv $SCRIPT_HOME/logs/log.txt $SCRIPT_HOME/logs/threadMon_$timestamp.log

find $SCRIPT_HOME/logs/threadMon_* -mtime +30 -exec rm {} \;
