Usage: This script takes 4 input paramaeters.
                1. Operation(GET/ABORT)
                2. Composite Name in partition/cmpName[version] format or ALL for all composite
                3. Start Time
                4. End Time
 Examples:
 1. To get all recoverable instances of composite SyncOrderCurrentPointsFromEBS:
    ./abortInstances.sh GET "default/SyncOrderCurrentPointsFromEBS[1.0]" "2021-08-15 04:00" "2021-08-15 10:00"
 2. To abort recoverable instances of composite SyncOrderCurrentPointsFromEBS:
    ./abortInstances.sh ABORT "default/SyncOrderCurrentPointsFromEBS[1.0]" "2021-08-15 04:00" "2021-08-15 10:00"
 3. To get all recoverable instances in a specific time period:
    ./abortInstances.sh GET ALL "2021-08-17 00:00" "2021-08-17 01:00"
 4. To abort all recoverable instances in a specific time period:
    ./abortInstances.sh ABORT ALL "2021-08-17 00:00" "2021-08-17 01:00"

 Note: Update env.properties and CLASSPATH in abortInstances.sh file according to target environment.
