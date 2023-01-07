SCRIPT_HOME=~/scripts/GetStats
source ~/scripts/env.properties
source $WLS_HOME/server/bin/setWLSEnv.sh
export CLASSPATH=$CLASSPATH:/oracle/products/fmw12.2.1.3/osb/lib/modules/*
cd ~/scripts/GetStats
timestamp=$(date +%Y-%m-%d-%H-%M)

source $WLS_HOME/server/bin/setWLSEnv.sh
java weblogic.WLST $SCRIPT_HOME/getStats.py

mv $SCRIPT_HOME/logs/OSBStats.log $SCRIPT_HOME/logs/OSBStats_$timestamp.log
find  ~/scripts/GetStats/logs/OSBStats* -mtime +10 -exec rm {} \;
