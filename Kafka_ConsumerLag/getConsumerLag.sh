#Desc: This scripts gets Kafka consumer lag. It sends email alert and writes
#data to wavefront. 
#
# Date          Author                   Description
# --------      -------------            ---------------------------------
# 09/08/22      Ramesh Poonati           Initial Version
#
#=========================================================================
#Change below variables as per your setup.
SCRIPT_HOME=
LOG_DIR=
TMP_DIR=$SCRIPT_HOME/tmp
KAFKA_BIN=/apps/data/kafka-test-app-a1/kafka_2.13-3.1.0/bin
timestamp=$(date +%Y-%m-%d-%H-%M)


threshold=1 #Change as deisred
mailingList="" #Change as deisred
IFS=$'\n'
re='^[0-9]+$'

for consumer in $($KAFKA_BIN/kafka-consumer-groups.sh  --describe --all-groups --bootstrap-server localhost:9092 | sed  '1,2d') # change kafka host and port
do
  consumer_group_name=`echo $consumer | awk ' { print $1 } '`
  if [ $consumer_group_name != "GROUP" ] && [ $consumer_group_name != "" ]
  then
    topic_name=`echo $consumer | awk ' { print $2 } '`
    partition=`echo $consumer | awk ' { print $3 } '`
    current_offset=`echo $consumer | awk ' { print $4 } '`
    log_end_offset=`echo $consumer | awk ' { print $5 } '`
    lag=`echo $consumer | awk ' { print $6 } '`
    consumer_id=`echo $consumer | awk ' { print $7 } '`
    host=`echo $consumer | awk ' { print $8 } '`
    client_id=`echo $consumer | awk ' { print $9 } '`

    if  [[ $lag =~ $re ]] ; then #Ignore if lag is non numeric like -.

       if [ $lag -ge $threshold ]
       then
          echo "<tr><td>$topic_name</td><td>$partition</td><td>$consumer_id</td><td>$lag</td></tr>" >> $TMP_DIR/mailBody.txt
       fi
    fi

    echo "$consumer_group_name $topic_name $partition $current_offset $log_end_offset $lag $consumer_id $host $client_id"
    echo "nonprod.kafka.custom.consumer.lag '$lag' source="kafka" EnvironmentName="test" consumer_group_name='$consumer_group_name' topic_name='$topic_name' partition='$partition' current_offset='$current_offset' log_end_offset='$log_end_offset' consumer_id='$consumer_id' host='$host' client_id='$client_id' " | tee -a $TMP_DIR/data.txt $LOG_DIR/kafka_lag_$timestamp.log > /dev/null
  fi
done

#Change bearer token and wavefront url.
cat $TMP_DIR/data.txt | curl --location --request POST  --header 'Authorization: Bearer XYZ' --header 'Content-Type: text/plain' -F file=@- 'https://abc.wavefront.com/report'

echo "TO:$mailingList"  > $TMP_DIR/mail.txt
echo "Subject: Kafka Consumer Lag" >>  $TMP_DIR/mail.txt
echo "Content-Type: text/html; charset="us-ascii"" >> $TMP_DIR/mail.txt
echo "<html>" >> $TMP_DIR/mail.txt
echo "<head><style>body {font-family:courier,serif} table {border-collapse: collapse; width:40% }table, td, th { border: 1px solid black; text-align: left}</style></head>" >> $TMP_DIR/mail.txt
echo "<body  text="black">" >> $TMP_DIR/mail.txt
echo "<h4>Following consumer groups have lag more than $threshold. </h4>" >> $TMP_DIR/mail.txt
echo '<table>' >> $TMP_DIR/mail.txt
echo '<tr><th>Topic Name</th><th>Partition No </th> <th>Consumer Name</th><th>Lag</th></tr>' >> $TMP_DIR/mail.txt

consumerCount=`cat $TMP_DIR/mailBody.txt | wc -l`

if [ $consumerCount -gt 0 ]
then
   cat $TMP_DIR/mailBody.txt >> $TMP_DIR/mail.txt 
   echo "</table>" >> $TMP_DIR/mail.txt
   echo "" >> $TMP_DIR/mail.txt
   echo "<br>" >> $TMP_DIR/mail.txt
   echo "</body>" >> $TMP_DIR/mail.txt
   echo "</html>" >> $TMP_DIR/mail.txt
   echo "" >> $TMP_DIR/mail.txt
   echo "" >> $TMP_DIR/mail.txt
   cat $TMP_DIR/mail.txt | /usr/sbin/sendmail -t
fi 
rm $TMP_DIR/mailBody.txt $TMP_DIR/mail.txt $TMP_DIR/data.txt
find $LOG_DIR/*.log -mtime +7 -exec rm {} \;
