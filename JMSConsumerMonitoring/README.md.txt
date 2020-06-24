Description - This wlst script checks consumers on jms queues and sends mail if there are no consumers. This can be customized furhter like queues to be monitored etc.

JMSConsumerMonitoring.py - wlst script which connects weblogic server and get conusmer count of JMS queue.

JMSConsumerMonitoring.sh - Wrapper script for wlst script. It sets up environment varaibles so that wlst script can be invoked directly from command line. Don't forget to update env file according to your setup.