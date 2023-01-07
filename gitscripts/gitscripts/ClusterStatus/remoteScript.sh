env=$1
IFS=', ' read -r -a ips <<< "$2"
bin_location=$3

rm clusterStatus.log
timestamp=$(date +%Y-%m-%d-%H-%M)

for ip in "${ips[@]}"
do
  time_diff=0
  if [ ! -f $bin_location/views/node.$ip.dat ]
  then
    echo "" >> clusterStatus.log
    echo "[$timestamp] [$env] File $bin_location/views/node.$ip.dat doesn't exist. Atom may not be running." >> clusterStatus.log
  else
    file_epochtime=`date -r $bin_location/views/node.$ip.dat +%s`
    current_epochtime=`date +%s`
    time_diff=$(( current_epochtime - file_epochtime ))

    if [ "$time_diff" -ge 600 ]
    then
      echo "" >> clusterStatus.log
      echo "[$timestamp] [$env] Timestamp of $bin_location/views/node.$ip.dat is more than 10 mins old. Node $ip seems to be unresponsive" >> clusterStatus.log
    fi
    problem=`grep problem $bin_location/views/node.$ip.dat`
  
    if [ ! -z "$problem" ]
    then
      echo "" >> clusterStatus.log
      echo "[$timestamp] [$env] There is a problem with the cluster ($ip): $problem" >> clusterStatus.log
    fi
  fi
done
cat clusterStatus.log
