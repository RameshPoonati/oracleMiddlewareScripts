#!/bin/bash
export HOME_DIR=/home/userName
source $HOME_DIR/scripts/envName.env
export SCRIPT_HOME=$HOME_DIR/scripts/DisableDiag
source $WLS_HOME/server/bin/setWLSEnv.sh

java weblogic.WLST $SCRIPT_HOME/disableDiag.py

