#Description: This script takes thread dump for the all java processes running on the machine
#User can choose for what servers thread dumps have to be taken.
#      
# Date          Author                   Description
# --------      -------------            ------------------------------------------------
# 10/30/17      Ramesh Poonati           Initial Version
#
#=============================================================================================

#Change below vairables according to your env
export SCRIPT_HOME=/orabpm/app/scripts/ThreadDump
export DUMP_DIR=$SCRIPT_HOME/dumps

export JAVA_HOME=/orabpm/app/oracle/jdk1.8.0_60
export PATH=$JAVA_HOME/bin:$PATH

timestamp=$(date +%Y-%m-%d-%H-%M-%S)
userName='orabpm' #User who started weblogc server.
sleepTime=10

servers=($(ps -ef | grep java | grep "^$userName"| awk '{ for(i = 1; i <= NF; i++) { if ( $i~ "weblogic.Name" ){  print  $i ":" $2;} } }' | sed 's/-Dweblogic.Name=//' | sort)) # Getting server names and pids.

printf "\n"
printf "Weblogic servers running on this machine:\n"
printf "++++++ ++++++++++++++\n"
printf "No  \t Server Name  \n"
printf "++++++ ++++++++++++++\n"

#Print server names and their number for user enter as input.
for i in "${!servers[@]}"
do
:
	serverName=$(echo "${servers[$i]}" | cut -d':' -f 1) 
	printf    "%s \t %s \n" $((i+1)) $serverName  
done

printf "++++++ ++++++++++++++\n"
printf "\n"
printf "Enter server numbers, seperated by commas, for which thread dumps need to be taken: " 

OLD_IFS=$IFS
IFS=','
read -ra input
IFS=$OLD_IFS

#Validate input
for i in "${!input[@]}" 
do
:
	if [ ${input[$i]} -lt 1 ] || [ ${input[i]} -gt "${#servers[@]}" ] 
	then
	printf "Invalid Input!!!\n"
	exit -100
	fi
done

printf "Enter number of thread dumps required: "
read dumpCount

CURR_DUMP_DIR=$DUMP_DIR/ThreadDump_$timestamp
mkdir $CURR_DUMP_DIR

#Print thread dumps

for (( k=1; k <= $dumpCount ; k++ ))
do
:
	echo " "
	for i in "${input[@]}" 
	do
	:
	serverName=$(echo "${servers[($i-1)]}" | cut -d':' -f 1)
	pid=$(echo "${servers[($i-1)]}" | cut -d':' -f 2)
	printf "Printing threads for server %s with PID %s ...\n" $serverName $pid
	timestamp=$(date +%Y-%m-%d-%H-%M-%S)
	`jcmd $pid Thread.print > $CURR_DUMP_DIR/$serverName\_$timestamp.log`
	done
echo "Sleeping for $sleepTime seconds"
sleep $sleepTime
done