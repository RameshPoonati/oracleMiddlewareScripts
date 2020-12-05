Description: This script identifies if the server is restarted during past x mins. This will be useful when server is crashing and auto restarted by node manager or when we want to have more control over restarts.It was tested on 12.1.3.0. May need minor changes on higher versions.

crashRestartAlert.py - wlst script which reads through server runtime to get if it was restarted recently.

crashRestartAlert.sh - Wrapper script for wlst script. It sets up environment varaibles so that wlst script can be invoked directly from command line. Don't forget to update env file according to your setup.