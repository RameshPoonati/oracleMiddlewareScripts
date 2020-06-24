#!/bin/bash
#=============================================================================================
#Module: Switches Proxy Service State
#

DOMAIN_BIN=/u03/app/oracle/osbprd/admin/osb_domain/mserver/osb_domain/bin
export DOMAIN_BIN

CLASSPATH=$CLASSPATH:/u03/app/oracle/osbprd/product/fmw/wlserver/server/lib/weblogic.jar:/u03/app/oracle/osbprd/product/fmw/osb/lib/modules/oracle.servicebus.kernel-api.jar:/u03/app/oracle/osbprd/product/fmw/osb/lib/modules/oracle.servicebus.kernel-wls.jar://u03/app/oracle/osbprd/product/fmw/osb/lib/modules/oracle.servicebus.configfwk-wls.jar:/u03/app/oracle/osbprd/product/fmw/osb/lib/modules/oracle.servicebus.configfwk.jar::/u03/app/oracle/osbprd/product/fmw/osb/lib/modules/*
export CLASSPATH

SCRIPT_HOME=/home/aosbprd/scripts/OSB_State_Change
export SCRIPT_HOME
echo "Enter the oparation:"
read switchOperation
#switchOperation=$1
echo "Operation is: $switchOperation"

source $DOMAIN_BIN/setDomainEnv.sh

cd $SCRIPT_HOME
java weblogic.WLST switchState_ProxyServices.py $1 $2 $switchOperation

#END OF SCRIP

