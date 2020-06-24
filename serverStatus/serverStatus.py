#============================================================================================
#
# Module: Weblogic Server Health Monitoring Script 
#
# Date          Author                    Description
# -----------   -------------             ------------------------------------------------
# 05/09/2018    Ramesh                    Original Version
#=============================================================================================
import smtplib
import sys, traceback

def findShutdownServers():
	shutdownServers = []
	try:
		connect('weblogic',password,url=URL,timeout=90000)
                domainConfig()
                global svrNames;
                svrNames = [];
                allServers=cmo.getServers();
		#print 'Server List';
		#print allServers;
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
		connect('weblogic',password,url=URL,timeout=90000)
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

env = 'PRD-OSB' # Change according to your env.
URL = 't3://hostname:port' # Change according to your env
password='' # Change according to your env
connectionError = "" 
logLocation  = '' # Change according to your env
logFile = open(logLocation,'w+')
notRunningServers = findShutdownServers();
if notRunningServers is None:
	notRunningServers = []
unhealthyServers = []
healthyServers = []
if connectionError != "True":
	svrList = []
	svrList = findHealthStatus();

	for svr in svrList: #Segregate servers on health state
		if svr[1]=='RUNNING' and svr[2]=='HEALTH_OK':
			healthyServers.append(svr);
		else:
			unhealthyServers.append(svr);

	if len(notRunningServers) > 0:
		print >> logFile, "Shutdown Servers: "
		print >> logFile, '-'*38
 		print >> logFile, "Server Name\t" + "State \t" 
		print >> logFile, '-'*38
 		for svr in notRunningServers:
        		print >> logFile, svr[0] + "\t" + svr[1];

	if len(unhealthyServers) > 0:
		print >> logFile, "\n"
		print >> logFile, "Not Healthy Servers: "
        	print >> logFile, '-'*120
        	print >> logFile, "Server Name\t" + "State\t\t" + "Health\t\t\t" + "Reason"
        	print >> logFile, '-'*120
        	for svr in unhealthyServers:
                	print >> logFile, svr[0] + "\t" + svr[1] + "\t" + svr[2] + "\t\t" + svr[3]
	
        if (len(healthyServers) + len(notRunningServers)) < len(svrNames):
                print >> logFile, "\n"
                print >> logFile, "Not Reachable Servers: "
                print >> logFile, '-'*54
                print >> logFile, "Server Name\t"
                print >> logFile, '-'*54
                for svr in svrNames:
                        if svr  not in [i[0] for i in healthyServers +  notRunningServers ]:
                                print >> logFile, svr

	if len(healthyServers) > 0:
		print >> logFile, "\n"
		print >> logFile, "Healthy Servers: "
		print >> logFile, '-'*54
		print >> logFile, "Server Name\t" + "State \t\t" + "Health"
		print >> logFile, '-'*54
		for svr in healthyServers:
			print >> logFile, svr[0] + "\t " + svr[1] + "\t " + "OK"   

logFile.close()
#Copy log file to mail file if there is any discrepancy.

if ( (len(notRunningServers) > 0)  | (len(unhealthyServers) > 0) | ((len(healthyServers) + len(notRunningServers) + len(unhealthyServers)) < len(svrNames)) | (connectionError == "True") ):
        sender = '' # Change according to your env
        receivers = [''] # Change according to your env
        message = """From:  \n MIME-Version: 1.0 \n Content-type: text/html \nSubject: Alert: Action Required """ + env + """ - Server(s) Health is Not Good \n""" # Change according to your env
	logFile = open(logLocation,'r')
	message = message + logFile.read() 
        try:
                smtpObj = smtplib.SMTP('localhost')
                smtpObj.sendmail(sender, receivers, message)
        except smtplib.SMTPException:
                print >> logFile, "Error: unable to send email"
