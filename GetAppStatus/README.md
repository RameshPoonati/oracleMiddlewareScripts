Description - This wlst script gets osb proxy service MDB status and sends an email alert if MDB is in ADMIN state. This script can be modifed to get status of any weblogic application.

threadMon.py - wlst script that get proxy MDB application status.

threadMon.sh - Wrapper script for wlst script. It sets up environment varaibles so that wlst script can be invoked directly from command line. Don't forget to update env file according to your setup.