#!/bin/bash
#Description: Wrappter shell script for parsing and sending metrics.

export HOME_DIR=/home/oracle
source $HOME_DIR/scripts/env.properties # This file contains WLS_HOME, PATH etc
export SCRIPT_HOME=$HOME_DIR/scripts/IWSReport_Extractor
source $WLS_HOME/server/bin/setWLSEnv.sh

timestamp=$(date +%Y-%m-%d-%H-%M)
java weblogic.WLST $SCRIPT_HOME/getIWSReport.py # Download IWS Report

python $SCRIPT_HOME/sendMetrics.py #Parse report and send metrics to Wavefront

mv $SCRIPT_HOME/tmp/IWSReport.xml $SCRIPT_HOME/tmp/IWSReport.xml_$timestamp
mv $SCRIPT_HOME/logs/IWSReports.log $SCRIPT_HOME/logs/IWSReports.log_$timestamp

find $SCRIPT_HOME/logs/IWSReports* -mtime +10 -exec rm {} \;
find $SCRIPT_HOME/tmp/IWSReport* -mtime +10 -exec rm {} \;
