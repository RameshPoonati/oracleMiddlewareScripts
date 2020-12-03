#Description: This script checks cpu, memory and swap usage and sends alert based on defined thresholds.
#      
# Date          Author                   Description
# --------      -------------            ------------------------------------------------
# 12/04/17      Ramesh Poonati           Initial Version
#
#=============================================================================================
SCRIPT_HOME=/home/oracle/scripts/CpuMemMon #Change according to your env.
SCRIPT_LOG=$SCRIPT_HOME/logs

timestamp=$(date +%Y-%m-%d-%H-%M)
ENV=DEVSOA1
HOST=`hostname`

#Change below thresholds as needed.
cpuUsageThreshold=85
freeMemThreshold=2048
swapUsageThreshold=4196

avgIdle=`mpstat 15 2 | tail -1 | awk '{ print $NF } '`
avgCpu=$(perl -e " use integer; print 100-$avgIdle")
echo "Average CPU Utilization: $avgCpu %. Threshold value is: $cpuUsageThreshold %" >> $SCRIPT_LOG/CpuMemMonitor$timestamp.log 

freeMem=`free -m | tail -2 | head -1 | awk '{ print $7 }'`
usedSwap=`free -m | tail -1 | awk '{ print $3 }'`
echo "Free Memory: $freeMem MB. Threshold value is: $freeMemThreshold MB" >>  $SCRIPT_LOG/CpuMemMonitor$timestamp.log
echo "Used SWAP: $usedSwap MB. Threshold value is: $swapUsageThreshold MB" >>  $SCRIPT_LOG/CpuMemMonitor$timestamp.log

if [ "$avgCpu" -gt $cpuUsageThreshold ] || [ "$freeMem" -lt $freeMemThreshold ] || [ "$usedSwap" -gt $swapUsageThreshold ]; then
	if [ "$avgCpu" -gt $cpuUsageThreshold ]; then
		cpu_color="RED"
		echo "<br><b>Following are top 10 cpu consuming processes:</b><br><br>" > $SCRIPT_LOG/topProcs.txt
		echo `ps -eo user,pid,ppid,cmd,%mem,%cpu,command --sort=-%cpu | head -10 | cut -c -500 | sed 's/$/<br><br>/'` >> $SCRIPT_LOG/topProcs.txt
	else
		cpu_color="WHITE"
	fi

	if [ "$freeMem" -lt $freeMemThreshold ]; then
		mem_color="RED"
		echo "<br><b>Following are top 10 memory consuming processes:</b><br><br>" >> $SCRIPT_LOG/topProcs.txt
		echo `ps -eo user,pid,ppid,cmd,%mem,%cpu,command --sort=-%mem | head -10 | cut -c -500 | sed 's/$/<br><br>/'` >> $SCRIPT_LOG/topProcs.txt
	else
		mem_color="WHITE"
	fi

	if [ "$usedSwap" -ge $swapUsageThreshold ]; then
		swap_color="RED"
	else
		swap_color="WHITE"
	fi

	TOLIST="add mail ids here"
	echo "Subject: $ENV - Resource Usage Alert in $HOST" >  $SCRIPT_LOG/mail.html
	echo "TO: $TOLIST" >> $SCRIPT_LOG/mail.html
	echo "Content-Type: text/html; charset="us-ascii"" >> $SCRIPT_LOG/mail.html
	echo "<html>" >> $SCRIPT_LOG/mail.html
	echo "<head><style>body {font-family:courier,serif} table {border-collapse: collapse; width:40% }table, td, th { border: 1px solid black; text-align: left}</style></head>" >> $SCRIPT_LOG/mail.html
	echo "<body  text="black">" >> $SCRIPT_LOG/mail.html
	echo "<h4>Resource Utilization at: $timestamp </h4>" >> $SCRIPT_LOG/mail.html
        echo "<table>" >> $SCRIPT_LOG/mail.html
        echo "<tr><th>Resource</th><th>Current </th> <th>Threshold</th></tr>" >> $SCRIPT_LOG/mail.html
        echo "<tr bgcolor="$cpu_color"><td>CPU Usage</td><td>$avgCpu %</td><td>$cpuUsageThreshold %</td></tr>" >> $SCRIPT_LOG/mail.html
        echo "<tr bgcolor="$mem_color"><td>Free Memory</td><td>`printf "%' .f" $freeMem` MB</td><td>$freeMemThreshold MB</td></tr>" >> $SCRIPT_LOG/mail.html
        echo "<tr bgcolor="$swap_color"><td>Swap Used</td><td>`printf "%' .f" $usedSwap` MB</td><td>$swapUsageThreshold MB</td></tr>" >> $SCRIPT_LOG/mail.html
        echo "</table>" >> $SCRIPT_LOG/mail.html
	cat $SCRIPT_LOG/topProcs.txt >> $SCRIPT_LOG/mail.html
	echo "<br>" >> $SCRIPT_LOG/mail.html
        echo "</body>" >> $SCRIPT_LOG/mail.html
        echo "</html>" >> $SCRIPT_LOG/mail.html
	/usr/sbin/sendmail -t -F "$HOST" < $SCRIPT_LOG/mail.html
        rm $SCRIPT_LOG/mail.html
	rm $SCRIPT_LOG/topProcs.txt
fi
find $SCRIPT_LOG/CpuMemMonitor* -mtime +30 -exec rm {} \;