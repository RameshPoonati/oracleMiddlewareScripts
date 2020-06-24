#=============================================================================================
#
# Module: Monitors SOA Adapter's Health.
#
# Date          Author                    Description
# -----------   -------------             ------------------------------------------------
# 10/09/2018    Ramesh                    Original Version
#=============================================================================================
import smtplib
import sys, traceback

def findRunningSOAServers(): # This function finds list of running SOA servers excluding Admin and WSM servers. 
        runningSOAServers = []
        try:
                connect('weblogic',password,url=URL,timeout=90000)
                domainConfig()
                allServers=cmo.getServers();
                domainRuntime()
                cd('/ServerLifeCycleRuntimes/')
                runningSOAServers = []
                for server in allServers:
                        serverName=server.getName()
                        cd(serverName)
                        serverState=cmo.getState()
                        if serverState=='RUNNING':
				runningSOAServers.append(serverName);
                        cd('..')
                runningSOAServers.sort();
                nonSOAServers = ['AdminServer','wsm_server1','wsm_server2']  # List of servers that are created but kept deliberately down.
                runningSOAServers = [server for server in runningSOAServers if server not in nonSOAServers]
                disconnect('force')
                return runningSOAServers;
        except Exception, e:
                global  connectionError
                connectionError = "True"
                print >> logFile, "Problem while connecting to Admin Server or Runtime exception !!"
                print >> logFile, '-'*100
                print >> logFile, str(e)
                print >> logFile, '-'*100

sendMail = '';
env = 'envName'
URL = 't3://hostname:port'
password=''
connectionError = ""
logLocation  = '/home/userName/scripts/AdapterStatus/logs/log.txt'
logFile = open(logLocation,'w+')

servers=findRunningSOAServers();
connect('weblogic',password,url=URL,timeout=90000)
domainRuntime();
adapterReport = ObjectName('oracle.soa.config:j2eeType=AdapterReportAggregatorMXBean,name=adapterreportaggregator');

print >> logFile, "Following Adapter Endpoints are down. Please take necessary actions as mentioned in below mail.";
print >> logFile, "\n";
print >> logFile, "Server Name \t" + "Composite Name \t\t" +  "Endpoint Name \t\t" + "Health \t\t" + "Type \t";

for svr in servers:
	params = [svr,'default'];	
	sign = ['java.lang.String','java.lang.String'];
	try:
		healthCompositeData=mbs.invoke(adapterReport, 'fetchAdapterEndpointsHealth', params, sign);
	except Exception, e: 
		print >> logFile, "Exception while fetching data. Please analyze further.";
		print >> logFile, str(e);
		sendMail = 'True';
		continue;

	key=array([svr],Object); #Tabular type expects key as array of Objects;
	health=healthCompositeData.get('endpointHealth').get(key); #Last get function gets data from Tabular Type

	if len(health.get('value')) > 0:
		sendMail = 'True';
		for i in range(len(health.get('value'))):
			print >> logFile, svr + "\t" + health.get('value')[i].get('compositeName') + "\t" + health.get('value')[i].get('endpointName') + "\t" + health.get('value')[i].get('health') + "\t" + health.get('value')[i].get('endpointType'); 

if sendMail == 'True':
	print >> logFile, "\nAction Plan:";
	print >> logFile, "\n1. Please do rolling restart SOA servers as per Server Bounce Matrix ONLY if adapters are down. Investiage further if you get connection or any other error.";

	sender = 'username@hostname'
	receivers = ['mailing_list'] 
	message = """From: hostname  <username@hostname> \n MIME-Version: 1.0 \n Content-type: text/html \nSubject: Alert: Action Required - """ + env + """ - Adapter(s) Health is Not Good \n"""
	logFile = open(logLocation,'r')
	message = message + logFile.read() 
	try:
		smtpObj = smtplib.SMTP('localhost')
	        smtpObj.sendmail(sender, receivers, message)
	except smtplib.SMTPException:
		print >> logFile, "Error: unable to send email"

disconnect('force');
