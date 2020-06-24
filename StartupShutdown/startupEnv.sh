#!/bin/bash
########################################################
#Module: Starts all the servers in the environemnt
#
#Date           Author          Description
#-----          ------          -----------
#08/03/2018     Ramesh         Original Version
########################################################

export SCRIPT_HOME=~/scripts

#Setup environment variables
. envName.env

logtime=$(date +%Y-%m-%d-%H-%M)
. $WLS_HOME/server/bin/setWLSEnv.sh

echo "" >> $SCRIPT_HOME/logs/startupEnv/startup_$logtime.log

#Start Node Manager
echo "" >> $SCRIPT_HOME/logs/startupEnv/startup_$logtime.log
echo "Starting NM..."  >> $SCRIPT_HOME/logs/startupEnv/startup_$logtime.log
. startMNM.sh >> $SCRIPT_HOME/logs/startupEnv/startup_$logtime.log
sleep 30s

#Start Admin Server
echo "" >> $SCRIPT_HOME/logs/startupEnv/startup_$logtime.log
echo "Starting Admin Server..."  >> $SCRIPT_HOME/logs/startupEnv/startup_$logtime.log
java weblogic.WLST $SCRIPT_HOME/startAS.py >> $SCRIPT_HOME/logs/startupEnv/startup_$logtime.log

#Start all managed servers
echo "" >> $SCRIPT_HOME/logs/startupEnv/startup_$logtime.log
echo "Starting all Managed Servers..."  >> $SCRIPT_HOME/logs/startupEnv/startup_$logtime.log
#java weblogic.WLST $SCRIPT_HOME/startCluster.py >> $SCRIPT_HOME/logs/startupEnv/startup_$logtime.log
java weblogic.WLST $SCRIPT_HOME/startMS.py >> $SCRIPT_HOME/logs/startupEnv/startup_$logtime.log
