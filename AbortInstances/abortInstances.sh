#!/bin/bash
########################################################################################################
#Description: This script is a wrapper script for wlst script to abort recoverable instances. 
#      
# Date          Author                   Description
# --------      -------------            ------------------------------------------------
# 18/08/21      Ramesh Poonati           Initial Version
#
#Usage: This script takes 4 input parmaeters. 
#                1. Operation(GET/ABORT) 
#                2. Composite Name in partition/cmpName[version] format or ALL for all composite
#                3. Start Time
#                4. End Time
# Examples:
# 1. To get all recoverable instances of composite SyncOrderCurrentPointsFromEBS:
#    ./abortInstances.sh GET "default/SyncOrderCurrentPointsFromEBS[1.0]" "2021-08-15 04:00" "2021-08-15 10:00"
# 2. To abort recoverable instances of composite SyncOrderCurrentPointsFromEBS:
#    ./abortInstances.sh ABORT "default/SyncOrderCurrentPointsFromEBS[1.0]" "2021-08-15 04:00" "2021-08-15 10:00"
# 3. To get all recoverable instances in a specific time period:
#    ./abortInstances.sh GET ALL "2021-08-17 00:00" "2021-08-17 01:00"
# 4. To abort all recoverable instances in a specific time period:
#    ./abortInstances.sh ABORT ALL "2021-08-17 00:00" "2021-08-17 01:00"
# 
# Note: Update env.properties and CLASSPATH accordingly.
#=============================================================================================

export HOME_DIR=/home/oracle
source $HOME_DIR/scripts/soadev12.env
export SCRIPT_HOME=$HOME_DIR/scripts/AbortInstances
cd $SCRIPT_HOME
export CLASSPATH=$CLASSPATH:<oracle home>/fmw12.2.1.3/soa/soa/modules/oracle.soa.fabric_11.1.1/tracking-api.jar
source $WL_HOME/server/bin/setWLSEnv.sh &>/dev/null
timestamp=$(date +%Y-%m-%d-%H-%M)
java weblogic.WLST $SCRIPT_HOME/abortInstances.py "$1" "$2" "$3" "$4"
