Description - This wlst script captures number of threads in weblogic and prints to log files. Can be used to monitor threads periodically by setting up cron job.

threadMon.py - wlst script which connects weblogic server and gets thread details.

threadMon.sh - Wrapper script for wlst script. It sets up environment varaibles so that wlst script can be invoked directly from command line. Don't forget to update env file according to your setup.