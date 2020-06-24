#!/bin/bash
#################################################################
#Module: Shuts down all the servers/components in the environemnt
#
#Date		Author 		Description
#-----		------		-----------
#08/03/2018	Ramesh		Original Version
#################################################################

export SCRIPT_HOME=~/scripts
#Setup environment variables
. envName.env

logtime=$(date +%Y-%m-%d-%H-%M)
. $WLS_HOME/server/bin/setWLSEnv.sh

#Stop all managed servers
echo "" >> $SCRIPT_HOME/logs/shutdownEnv/shutdown_$logtime.log
echo "Stopping Managed Servers..."  >> $SCRIPT_HOME/logs/shutdownEnv/shutdown_$logtime.log
java weblogic.WLST $SCRIPT_HOME/stopMS.py >> $SCRIPT_HOME/logs/shutdownEnv/shutdown_$logtime.log

#Stop Admin Server
echo "" >> $SCRIPT_HOME/logs/shutdownEnv/shutdown_$logtime.log
echo "Stopping Admin Server..."  >> $SCRIPT_HOME/logs/shutdownEnv/shutdown_$logtime.log
java weblogic.WLST $SCRIPT_HOME/stopAS.py >> $SCRIPT_HOME/logs/shutdownEnv/shutdown_$logtime.log

#Stop Node Manager
echo "" >> $SCRIPT_HOME/logs/shutdownEnv/shutdown_$logtime.log
echo "Stopping NM..."  >> $SCRIPT_HOME/logs/shutdownEnv/shutdown_$logtime.log
(. stopMNM.sh) >> $SCRIPT_HOME/logs/shutdownEnv/shutdown_$logtime.log

echo "" >> $SCRIPT_HOME/logs/shutdownEnv/shutdown_$logtime.log

processCount=`ps -ef | grep -E "java|ohs" | grep -v "agent_13c" | grep -v "grep" | wc -l`

if [ $processCount -eq 0 ];then
        echo "All middleware components are down. You can safely power off VM." >> $SCRIPT_HOME/logs/shutdownEnv/shutdown_$logtime.log
fi

