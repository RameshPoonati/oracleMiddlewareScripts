#Description: This scripts checks the certificate validity.
#Credits: Core of this script is taken from internet. I haven't noted down the original author name. Apologies.
#      
# Date          Author                   Description
# --------      -------------            ------------------------------------------------
# 03/12/20                               Initial Version.
#
#=============================================================================================
export SCRIPT_HOME=/home/oracle/scripts/JKSCertCheck #Change as per your env
export SCRIPT_LOG=$SCRIPT_HOME/logs

timestamp=$(date +%Y-%m-%d-%H-%M)
ENV=DEV #Change as per you env.
HOST=`hostname`
export JAVA_HOME=/u01/jdk #Change as per your env
export PATH=$JAVA_HOME/bin:$PATH

CURRENT=`date +%s`
alertDays=30 #Minimum number of days before certificate expiry you wish to receive alert

KEYSTORE=/u01/jdk/jre/lib/security/cacerts #Change as per your env
PASSWORD=changeit #Change as per your env

echo "$(keytool -list -v -keystore $KEYSTORE -storepass $PASSWORD)" > certs.log

certDetails=`awk ' {
if ( match($0,"Alias name:")) {
	count++ 
	if (count == 1) {
	printf substr($0, RSTART+RLENGTH+1) "#";
	}
	else {
	printf "\n" substr($0, RSTART+RLENGTH+1) "#";
	}
}
else if ( match($0,"until:")) {
	printf substr($0, RSTART+RLENGTH) "#";
}	
else { printf ""; 
} 
}
END{print "";}' certs.log`

while read -r cert; do		
	newLine="True"
	endLine="False"
	certificateCount=0
		while [ "$endLine" == "False" ]; do
		
		endIndex=`expr index "$cert" "#"`
		if [ $endIndex -eq 0 ];then
			endLine="True"
			break
		fi
		if [ "$newLine" == "True" ]; then
			aliasName=`echo ${cert:0:$endIndex-1}`
			newLine="False"
			cert=`echo ${cert:$endIndex}`
		else
			dateString=`echo ${cert:0:$endIndex-1}`
			((certificateCount++))
			cert=`echo ${cert:$endIndex}`
			dateEpoch=`date -d "$dateString" +%s`
			validityLeft=$(( ($dateEpoch -  $(date +%s)) / 60 / 60 / 24 ))
			if [[ $validityLeft -le $alertDays && $validityLeft -gt 0 ]]; then #ignore expired certificates
				echo "Certificate ($certificateCount) of alias $aliasName expires in $validityLeft days." | tee -a mail.dat $SCRIPT_LOG/certiCheck_$timestamp.log
				echo "" | tee -a mail.dat $SCRIPT_LOG/certiCheck_$timestamp.log
				sendMail="True"
			fi
		fi
	done
done <<< "$certDetails"

echo "" | tee -a mail.dat $SCRIPT_LOG/certiCheck_$timestamp.log

if [ "$sendMail" = "True" ]
then

mailx -s "$ENV - $HOST: Certificate Expiration Alert" -c "$CC" "list of email ids separated by space"<mail.dat

fi

rm mail.dat
rm certs.log
find $SCRIPT_LOG/certiCheck_* -mtime +30 -exec rm {} \;
