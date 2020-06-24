#=============================================================================================
#
# Module: Sends mail if there are no consumers on JMS destinations.
#
# Date          Author                    Description
# -----------   -------------             ------------------------------------------------
# 03/06/2019    Ramesh                    Original Version
#=============================================================================================
import smtplib
import time as pytime
import sys, traceback

def getConsumerMessgCount(): # This function finds number of consumers and messages in JMSModule. 
        try:
                connect(username,password,url=URL,timeout=90000)
                servers = domainRuntimeService.getServerRuntimes();
		destWithNoConsumer = []
		queues2Monitored = ['queue1', 'queue2', 'queue3']
		if (len(servers) > 0):
		    for server in servers:
			#print server
        		jmsRuntime = server.getJMSRuntime();
        		jmsServers = jmsRuntime.getJMSServers();
        		for jmsServer in jmsServers:
            			destinations = jmsServer.getDestinations();
         			for destination in destinations:
					#print destination
					
				     	if destination.getName()[:len(JMSModule)] == JMSModule:  #Filters only JMSModule 
						#print destination.getName();
				 		a,destName = destination.getName().split('@');
						b,jmsServerName = destination.getName().split('!');
						#print destName
						if destination.getConsumersCurrentCount() == 0 and destName in queues2Monitored:
							destWithNoConsumer.append(jmsServerName);
		destWithNoConsumer1 = [dest for dest in destWithNoConsumer  if dest in queues2Monitored]
		disconnect('force')
                return destWithNoConsumer;
        except Exception, e:
                global  connectionError
                connectionError = "True"
		mailFlag = 'True';
                print >> mailFile, "Problem while connecting to Admin Server or Runtime exception !!"
                print >> mailFile, '-'*100
                print >> mailFile, str(e)
                print >> mailFile, '-'*100	
		sendMail(mailFile)

def html_table(destWithNoConsumer,mailFile):
#	print >> mailFile, "\n";
	print >> mailFile, 'Content-Type: text/html; charset="us-ascii"'
	print >> mailFile, '<html>'
	print >> mailFile, "Following JMS destinations have no consumer:";
	print >> mailFile, '<style>table {  font-family: arial, sans-serif;  border-collapse: collapse; }td, th {  border: 1px solid #dddddd;  text-align: left;  padding: 8px;}tr:nth-child(even) {  background-color: #dddddd;}</style>'
	print >> mailFile, '<body  text="black">'
	print >> mailFile, '<table>'
	print >> mailFile, '<tr><th>Destination Name</th></tr>'
        print >> mailFile, '  <tr><td>'
	print >> mailFile, '  <tr><td>'.join(destWithNoConsumer)
	#print >> mailFile, '    </td><td>'.join(destWithNoConsumer)
	print >> mailFile, '  </td></tr>'
	print >> mailFile, '</table>'
#        print >> mailFile, '</html>'
#        print >> mailFile, '</body>'

def sendMail(mailFile):
	
	print >> mailFile, "<p>Action Plan:</p>";
        print >> mailFile, "<p>Please inform team that there are no consumers on the above JMS destination.</p>";
	print >> mailFile, '</html>'
	print >> mailFile, '</body>'

	sender = 'user@hostname'
	receivers = ['emailid1', 'emailid2']
	message = """From: """ +  sender + """ \n MIME-Version: 1.0 \n Content-type: text/html \nSubject: Alert: Action Required - """ + env + """ -  JMS Consumer Monitoring \n"""
	mailFile = open(mailLocation,'r')
	message = message + mailFile.read() 
	try:
		smtpObj = smtplib.SMTP('localhost')
	        smtpObj.sendmail(sender, receivers, message)
	except smtplib.SMTPException:
		print >> mailFile, "Error: unable to send email"
	sys.exit(1)

mailFlag  = '';
loadProperties('./config.properties')
currTime = pytime.strftime("%d/%m/%Y %H:%M:%S")
URL = 't3://' + adminHost + ':' + adminPort
connectionError = ""
mailFile = open(mailLocation,'w+')
logFile = open(logLocation,'w+')

destWithNoConsumer=getConsumerMessgCount();
html_table(destWithNoConsumer,mailFile)

if len(destWithNoConsumer) > 0:
        mailFlag = 'True';
	
#Write Log File.
for dest in destWithNoConsumer:
	print >> logFile, "[" + currTime + "]" + "," + dest; 

if mailFlag == 'True': #Uncomment this section to receive mail alerts.
        sendMail(mailFile)
