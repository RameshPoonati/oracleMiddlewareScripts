Description - This wlst script was tested against 11g. It caputes audit trail from dehydration store. I used it for getting time taken for reference call. But parser can be modified to suit your needs.

referenceInstances.py - wlst script to retreive audit trail.

referenceInstances.sh - Wrapper script for wlst script. It sets up environment varaibles so that wlst script can be invoked directly from command line. Don't forget to update env file according to your setup.

parser.sh - Parases audit trail and caputes time taken by reference service call.