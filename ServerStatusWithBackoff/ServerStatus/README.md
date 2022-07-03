Description - This wlst script checks the health of weblogic servers and sends mail if any of the servers is shutdown, in warnng state. This script exponentially backs-off while sending alerts. So, it is reduces number of alerts during weekends and extended maintenance periods.

serverStatus.py - wlst script which connects weblogic server and server state and health details. Don't forget to change env varaibles according to your setup.

serverStatus.sh - Wrapper script for wlst script. It sets up environment varaibles so that wlst script can be invoked directly from command line. Don't forget to update env file according to your setup.