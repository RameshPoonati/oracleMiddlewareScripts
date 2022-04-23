Description: This script checks health of weblogic/soa/osb datasources and sends an alert if datasource test fails.

dsAlert.py - wlst script which reads through datasource runtime to check health datasource pool.

dsAlert.sh - Wrapper script for wlst script. It sets up environment varaibles so that wlst script can be invoked directly from command line. Don't forget to update env file according to your setup.

Sample soadev12.env is added for reference.