#=============================================================================================
#
#Description: This script identifies if the server is restarted during past x mins. This will
#be useful when server is crashing and auto restarted by node manager or when we want to have more
#control over restarts.It was tested on 12.1.3.0. May need minor changes on higher versions.
#
# Date          Author                    Description
# -----------   -------------             ------------------------------------------------
# 07/21/2017    Ramesh Poonati            Initial Version
#=============================================================================================
import time as pyTime
import smtplib

def getRestartedServers(interval):
	serverList = []
	try:
		connect(username,password,url=URL,timeout=90000)
                domainRuntime()
                servers=domainRuntimeService.getServerRuntimes()
                for server in servers:
                        serverData = [];
                        serverName=server.getName()
                        serverActTime=server.getActivationTime()
                        diffMinutes = (int(pyTime.time()) - (serverActTime/1000)) / 60 #Activation time has 3 decimal points.
                        if ( 0 <= diffMinutes <= interval):
                                serverData.append(serverName)
                                serverData.append(diffMinutes)
                                serverList.append(serverData);
                serverList.sort();
	except Exception, e:
		print >> logFile, "Problem while connecting to Admin Server or RunTime error!!!"
	        print >> logFile, '-'*100
                print >> logFile, str(e)
                print >> logFile, '-'*100
	disconnect('force')
	return serverList;

#Change below parameters according to your env.
env = 'QA'
domain = 'SOA'
URL = 't3://host:7001' 
username = 'weblogic'
password = 'guessit'
logLocation  = '/orabpm/app/scripts/ServerCrashRestartAlert/logs/log.txt'
logFile = open(logLocation,'w+')
svrList = []
interval = 30 

svrList = getRestartedServers(interval)
if (len(svrList) > 0):
	print >> logFile, "Server(s) restarted in last " + str(interval) + " minutes:" 
	print >> logFile, "\n"
	for svr in svrList: 
		print >> logFile, svr[0]
logFile.close()

if len(svrList) > 0:
        sender = 'username@hostName' #change user id and hostname according to your env
        receivers = ['Comma separated email ids, for examaple 'abc@my.company', 'xyz@my.company.com']
        message = """From: hostName  <username@hostName> \n MIME-Version: 1.0 \n Content-type: text/html \nSubject: Alert: """ + env + " -  " + domain +  """ Server(s) Restarted or Crashed \n"""
	logFile = open(logLocation,'r')
	message = message + logFile.read() 
        try:
                smtpObj = smtplib.SMTP('localhost')
                smtpObj.sendmail(sender, receivers, message)
        except smtplib.SMTPException:
                print >> logFile, "Error: unable to send email"
