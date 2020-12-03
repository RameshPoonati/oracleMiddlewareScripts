#==================================================================================
#Description: This scripts checks the certificate validity for a given set of urls.
#
#Credits: https://gist.github.com/cgmartin/49cd0aefe836932cdc96
#Modified original script to check multiple urls.
#
#===================================================================================
SCRIPT_HOME=/home/oracle/scripts/urlCertCheck #Change as per your env
SCRIPT_LOG=$SCRIPT_HOME/logs
timestamp=$(date +%Y-%m-%d-%H-%M)
ENV="Non PROD" #Change as per your env

alertDays=30 #Minimum number of days before certificate expiry you wish to receive alert
urls=`cat $SCRIPT_HOME/cert.properties | grep urls | cut -d'=' -f 2` #Get list of urls for which expiry date needs to be checked.
recipients=`cat $SCRIPT_HOME/cert.properties | grep "email_ids" | cut -d'=' -f 2` #Get email ids of alert recipients.
alertDate=$(($(date +%s) + (86400*$alertDays)))


for url in $(echo $urls | sed "s/,/ /g")
do
   expirationdate=$(date -d "$(: | openssl s_client -connect $url:443 -servername $url 2>/dev/null \
                              | openssl x509  -text \
                              | grep 'Not After' \
                              |awk '{print $4,$5,$7}')" '+%s'); 

   if [ $alertDate -gt $expirationdate ]; then
      echo "Certificate for $url expires in less than $alertDays days, on $(date -d @$expirationdate '+%Y-%m-%d')" >> $SCRIPT_LOG/cert_expiry_$timestamp.log
      echo "" >> $SCRIPT_LOG/cert_expiry_$timestamp.log
   else
      echo "OK - Certificate for $url expires on $(date -d @$expirationdate '+%Y-%m-%d')" >> $SCRIPT_LOG/cert_valid_$timestamp.log
      echo "" >> $SCRIPT_LOG/cert_valid_$timestamp.log
   fi;
done

num_certs_expiring=0
if test -f "$SCRIPT_LOG/cert_expiry_$timestamp.log"; then
  num_certs_expiring=`wc -l $SCRIPT_LOG/cert_expiry_$timestamp.log | cut -d ' ' -f 1`
fi

if [ $num_certs_expiring -gt 0 ]
then
        echo "TO: $recipients" > $SCRIPT_LOG/mail.txt
        echo "Subject: Warning !!! $ENV TLS Certificate Expiry Alert" >>  $SCRIPT_LOG/mail.txt
        echo "Below certificates are expiring soon:" >> $SCRIPT_LOG/mail.txt
        echo "" >> $SCRIPT_LOG/mail.txt
        cat $SCRIPT_LOG/cert_expiry_$timestamp.log >> $SCRIPT_LOG/mail.txt
        echo "" >> $SCRIPT_LOG/mail.txt
        cat $SCRIPT_HOME/logs/mail.txt | /usr/sbin/sendmail -t
fi

find $SCRIPT_LOG/cert*.log -mtime +30 -exec rm {} \;
rm $SCRIPT_LOG/mail.txt 2>/dev/null #Suppress delete error message if no mail file is generated.