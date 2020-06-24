#=============================================================================================
#
# Module: Fetches current message count in all JMS destintations of a JMS module.
#
# Date          Author                    Description
# -----------   -------------             ------------------------------------------------
# 27/03/2019    Ramesh Poonati            Original Version
#=============================================================================================
import smtplib
import time as pytime
import sys, traceback

def getConsumerMessgCount(): # This function finds number of consumers and messages in JMSModule. 
        try:
                connect(username,password,url=URL,timeout=90000)
                servers = domainRuntimeService.getServerRuntimes();
		jmsStatusAll = []
		if (len(servers) > 0):
		    for server in servers:
			#print server
        		jmsRuntime = server.getJMSRuntime();
        		jmsServers = jmsRuntime.getJMSServers();
        		for jmsServer in jmsServers:
            			destinations = jmsServer.getDestinations();
         			for destination in destinations:
					jmsStatus = []
				     	if destination.getName()[:len(JMSModule)] == JMSModule:  #Filters only JMSModule 
				 		a,destName = destination.getName().split('@');
						#print destName
						isExist = '';
						for status in jmsStatusAll:
							if status[0] == destName:
								isExist = 'True';
								status[1] = status[1] + destination.getConsumersCurrentCount();
								messageCount = destination.getMessagesCurrentCount();
								if messageCount > 0:
        								for i in range(int(refetchCount)): #Refetch and mark growth if there are messages.
                								pytime.sleep(int(refetchSleepTime))
                								messageCountRefetch = destination.getMessagesCurrentCount();
                								jmsStatus.append(messageCountRefetch);
                								if messageCountRefetch < messageCount and ( int(status[3]) == 0 or int(status[3]) == 1):
                        								status[3] = '0';
                								elif messageCountRefetch == messageCount and ( int(status[3]) == 1):
                        								status[3] = '1';
                								elif messageCountRefetch > messageCount:
                        								status[3] = '2';
								status[2] = status[2] + destination.getMessagesCurrentCount();
								break;
						
						if isExist != 'True':
							jmsStatus.append(destName);
							jmsStatus.append(destination.getConsumersCurrentCount());
							messageCount = destination.getMessagesCurrentCount();
							growthFlag = 0;
							if messageCount > 0:
								for i in range(int(refetchCount)): #Refetch and mark growth if there are messages.
									pytime.sleep(int(refetchSleepTime))
									messageCountRefetch = destination.getMessagesCurrentCount();
									jmsStatus.append(messageCountRefetch);
									if messageCountRefetch < messageCount:
										growthFlag = '0';
									elif messageCountRefetch == messageCount:
										growthFlag = '1';
                                                                 	elif messageCountRefetch > messageCount:
										growthFlag = '2';
							else:
								jmsStatus.append(messageCount);
							jmsStatus.append(growthFlag);
							#print jmsStatus
							jmsStatusAll.append(jmsStatus);
		disconnect('force')
                return jmsStatusAll;
        except Exception, e:
                global  connectionError
                connectionError = "True"
		mailFlag = 'True';
                print >> mailFile, "Problem while connecting to Admin Server or Runtime exception !!"
                print >> mailFile, '-'*100
                print >> mailFile, str(e)
                print >> mailFile, '-'*100	
		sendMail()

def getDestIncorrConsumers(jmsStatus): #Returns JMS with count not requal to zero. By design JDA should have only 1 consumer.

	reportConsumer = [];
	for dest in consumer2Monitored:
        	for status in jmsStatus:
                	if status[0] == dest and status[1] != 1:
                        	reportConsumer.append(status);
	return reportConsumer;

def getDestWithMessages(jmsStatus,thresholdsDict): #Returns JMS with pending count greater than threshold.

	reportMessages = [];
	for status in jmsStatus:
		statusWithThreshold = []
		threshold = thresholdsDict.get(status[0],defualtThreshold)
		if status[2] > int(threshold):
			statusWithThreshold.append(status[0])
			statusWithThreshold.append(str(status[2]))
			statusWithThreshold.append(threshold)
			if status[3] == '0':
				statusWithThreshold.append('&darr;') #Add html down arrow.
			elif  status[3] == '1':
				statusWithThreshold.append('&harr;') #Add html horizontal arrow.
			elif  status[3] == '2':
				statusWithThreshold.append('&uarr;')#Add html up arrow.
	
              		reportMessages.append(statusWithThreshold);
	return reportMessages;

def loadThresholds():  #Load thresholds to dict.

	thresholds = {}
	thresholds_file = open("queue.thresholds")
	while 1: #Load thresholds to dict.
    		queueLine  = thresholds_file.readline()
    		if not queueLine:
        		break
    		if ("=" in queueLine and not queueLine.startswith("#") ):
        		queue,threshold = queueLine.strip().split('=')
        		thresholds[queue] = threshold
	return thresholds

def html_table(destWithMessages,mailFile):
	print >> mailFile, 'Content-Type: text/html; charset="us-ascii"'
	print >> mailFile, '<html>'
	print >> mailFile, '<style>table {  font-family: arial, sans-serif;  border-collapse: collapse; }td, th {  border: 1px solid #dddddd;  text-align: left;  padding: 8px;}tr:nth-child(even) {  background-color: #dddddd;}</style>'
	print >> mailFile, '<body  text="black">'
	print >> mailFile, '<table>'
	print >> mailFile, '<tr><th>Destination Name</th><th>Currrent Count</th><th>Threshold</th><th>Growth</th></tr>'
	for sublist in destWithMessages:
		print >> mailFile, '  <tr><td>'
		print >> mailFile, '    </td><td>'.join(sublist)
		print >> mailFile, '  </td></tr>'
	print >> mailFile, '</table>'
        print >> mailFile, '</html>'
        print >> mailFile, '</body>'

def sendMail():

	#print >> mailFile, "\nAction Plan:";
	#print >> mailFile, "\n1. If consumer count is zero: Inform JDA team that there are no active consumer on the respective JMS.";
	sender = 'aosbprd@cem4sosbaprd01'
        receivers = ['GlobalSSMW@specsavers.com', 'GlobalSSAMS@specsavers.com']
        #receivers = ['ramesh.poonati@specsavers.com']
	#receivers = ['GlobalSSMW@specsavers.com'] 
	message = """From: """ +  sender + """ \n MIME-Version: 1.0 \n Content-type: text/html \nSubject: Alert: Action Required - """ + env + """ - JMS Monitoring \n"""
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

thresholdsDict = loadThresholds();
jmsStatus=getConsumerMessgCount();
destWithMessages = getDestWithMessages(jmsStatus,thresholdsDict);
html_table(destWithMessages,mailFile)


if len(destWithMessages) > 0:
	mailFlag = 'True';


#Write Log File.
	for status in jmsStatus:
		print >> logFile, "[" + currTime + "]" + "," + status[0] + "," + str(status[1]) + "," +  str(status[2]);


if mailFlag == 'True': #Uncomment this section to receive mail alerts.
        sendMail()
