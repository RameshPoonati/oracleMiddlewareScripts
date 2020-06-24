Description - This wlst script checks number of messages in all queues in a JMS modules and sends mail based on threshold defined. Also, gives trend whether message count is increasing or decreasing.

QueueMonitoring.py - wlst script which connects weblogic server and gets JMS stats.

threadMon.sh - Wrapper script for wlst script. It sets up environment varaibles so that wlst script can be invoked directly from command line. Don't forget to update env file according to your setup.