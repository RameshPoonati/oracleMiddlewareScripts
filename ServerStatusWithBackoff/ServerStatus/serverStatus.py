#============================================================================================
#
# Module: Weblogic Server Health Monitoring Script 
#
# Date          Author                    Description
# -----------   -------------             ------------------------------------------------
# 12/04/2022    Ramesh                    Initial Version
#=============================================================================================
import smtplib
import sys, traceback

def findShutdownServers():
	shutdownServers = []
	try:
                global svrNames;
                svrNames = [];
		connect(usrname,password,url=URL,timeout=90000)
                domainConfig()
                allServers=cmo.getServers();
                domainRuntime()
                cd('/ServerLifeCycleRuntimes/')
                shutdownServers = []
                for server in allServers:
                        serverData = []
                        serverName=server.getName()
			svrNames.append(serverName);
                        cd(serverName)
                        serverState=cmo.getState()
                        if serverState!='RUNNING':
                                serverData.append(serverName);
                                serverData.append(serverState);
                                shutdownServers.append(serverData);
                        cd('..')
                shutdownServers.sort();
		unusedServers = [['bam_server1', 'SHUTDOWN']]  # List of servers that are created but kept deliberately down.
 		shutdownServers = [server for server in shutdownServers if server not in unusedServers]
        	disconnect('force')
        	return shutdownServers;
	except Exception, e:
		global	connectionError 
		connectionError = "True"
		print >> logFile, "Problem while connecting to Admin Server or Runtime exception !!"
		print >> logFile, '-'*100
		print >> logFile, str(e)
		print >> logFile, '-'*100

def findHealthStatus():
	serverList = []
	try:
		connect(usrname,password,url=URL,timeout=90000)
	        domainRuntime()
                cd('ServerRuntimes')
                servers=domainRuntimeService.getServerRuntimes()
                for server in servers:
                        serverData = [];
                        overallHealth = ''
                        serverState = '';
                        serverName=server.getName();
                        serverData.append(serverName);
                        serverState=server.getState()
                        serverData.append(serverState);

                        overallHealth=str(server.getOverallHealthState());
                        serverData.append(overallHealth.split(',')[2].split('State:')[1]);
			serverData.append(overallHealth.split('ReasonCode:')[1]);
                        serverList.append(serverData);

                serverList.sort();
       		disconnect('force')
    		return serverList;
	except Exception, e:
		global connectionError 
		connectionError = "True"
		print >> logFile, "Problem while connecting to Admin Server or RunTime error !!!"
	        print >> logFile, '-'*100
                print >> logFile, str(e) 
                print >> logFile, '-'*100

def getAlertCount():
	countFile = open(alertsCountLoc)
	alertCountStr = countFile.read().replace('\n', '')
	if alertCountStr == '' or alertCountStr == ' ':
		alertCount = 0
	else:
        	alertCount = int(alertCountStr)
	countFile.close()
        return alertCount

def backoff_alert(alertCount):
	for i in range(15):
		expValue = 2 ** i
                if expValue == alertCount:
                	return "True"
                elif expValue > alertCount:
                        return "False"

connectionError = "" 
unhealthyServers = []
healthyServers = []
allIsWell = ''
sendMail = ''
alertType = ''
loadProperties('/home/oracle/scripts/ServerStatus/script.properties')
logFile = open(logLocation,'w+')

notRunningServers = findShutdownServers();

if notRunningServers is None:
	notRunningServers = []

if connectionError != "True":
	svrList = []
	svrList = findHealthStatus();

	for svr in svrList: #Segregate servers on health state
		if svr[1]=='RUNNING' and svr[2]=='HEALTH_OK':
			healthyServers.append(svr);
		else:
			unhealthyServers.append(svr);

	if len(notRunningServers) > 0:
                print >> logFile, '<p style="color:Tomato;">Shutdown Servers:</p>'
 		print >> logFile, '<table>'
 		print >> logFile, '<tr><th>Server</th></tr>'
 		for svr in notRunningServers:
        		print >> logFile,  '<tr><td>' + svr[0] + '</td></tr>'
 		print >> logFile, '</table>'

	if len(unhealthyServers) > 0:
		print >> logFile, "<br>" 
                print >> logFile, '<p style="color:Tomato;">Not Healthy Servers:</p>'
 		print >> logFile, '<table>'
 		print >> logFile, '<tr><th>Server</th><th>State</th><th>Health</th><th>Reason</th></tr>'
        	for svr in unhealthyServers:
                	print >> logFile, '<tr><td>' + svr[0] + '</td><td>'  + svr[1] + '</td><td>'  + svr[2] + '</td><td>'  + svr[3] + '</td></tr>'
 		print >> logFile, '</table>'
	
        if (len(healthyServers) + len(notRunningServers)) < len(svrNames):
                print >> logFile, "<br>"
                print >> logFile, '<p style="color:Tomato;">Not Reachable Servers:</p>'
 		print >> logFile, '<table>'
                print >> logFile, '<tr><th>Server</th><tr>'
                for svr in svrNames:
                        if svr  not in [i[0] for i in healthyServers +  notRunningServers ]:
                                print >> logFile, '<tr><td>' + svr + '</td></tr>'
 		print >> logFile, '</table>'

	if len(healthyServers) > 0:
		print >> logFile, "<br>"
		print >> logFile, '<p style="color:MediumSeaGreen;">Healthy Servers:</p>'
 		print >> logFile, "<table>"
 		print >> logFile, "<tr><th>Server</th><th>State</th></tr>"
		for svr in healthyServers:
                	print >> logFile, "<tr><td>" + svr[0] + "</td><td>"  + svr[1] + "</td></tr>"
 		print >> logFile, "</table>"

logFile.close()
alertCount = getAlertCount()

if ( (len(notRunningServers) > 0)  | (len(unhealthyServers) > 0) | ((len(healthyServers) + len(notRunningServers) + len(unhealthyServers)) < len(svrNames)) | (connectionError == "True") ):
	allIsWell = 'False'

countFile = open(alertsCountLoc,'w')
if allIsWell != 'False':
	if alertCount >  0:
           alertType = "Cleared: "
           sendMail = "True"
        else:
           sendMail = "False"
        countFile.write("0")
else:
	if alertCount == 0:
		sendMail = "True"
                
        else:
                sendMail = backoff_alert(alertCount)
        alertType = 'Alert# ' + str(alertCount + 1) + ': '
        countFile.write(str(alertCount + 1))

countFile.close()
	
if ( sendMail == "True" ):
        message = """From:""" + sender + """\nTo:""" + receivers  + """\nMIME-Version: 1.0 \nContent-type: text/html \nSubject: """ + alertType +  env + """ - Server(s) Health is Not Good \n""" # Change according to your env
	logFile = open(logLocation,'r')
        message = message + '<html><head><style>body {font-family:courier,serif} table {border-collapse: collapse; width:40% }table, td, th { border: 1px solid black; text-align: left}</style></head><body  text="black">' 
	message = message + logFile.read() 
        message = message + '<p><b>Note</b>: This alert will be exponentially backed off and alert number in subject refers to amount of intervals passed since first alert.</p>'
        message = message + '</body></html>'
        receiversList=receivers.split(',')
        try:
                smtpObj = smtplib.SMTP('localhost')
                smtpObj.sendmail(sender, receiversList, message)
        except smtplib.SMTPException:
                print('Error: unable to send email')
