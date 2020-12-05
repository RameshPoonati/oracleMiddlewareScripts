#=============================================================================================
#
# Description: Monitoris Weblogic/SOA/OSB Data Source health and sends an email alert.
#
# Date          Author                    Description
# -----------   -------------             ------------------------------------------------
# 11/08/2017    Ramesh Poonati            Initial Version
#=============================================================================================
import smtplib
import sys, traceback

def findDSStatus():
	notRunningDS = []
	try:
		connect(username,password,url=URL,timeout=90000)
		svrList=domainRuntimeService.getServerRuntimes()
		
        completeDSList = []

        for server in svrList:
			notRunningDS = []
            serverName=server.getName()
			jdbcRuntime=server.getJDBCServiceRuntime()
			jdbcDSlist=jdbcRuntime.getJDBCDataSourceRuntimeMBeans()

			for ds in jdbcDSlist:
				dsData = []
				jdbcName=ds.getName()
      			jdbcState=ds.getState()
				testResult = ds.testPool()
				if testResult is not None:
					testResult = 'Failed'
				else:
					testResult = 'Passed'

                if(jdbcState != 'Running'):
                    dsData.append(jdbcName)
                    dsData.append(jdbcState)
                    dsData.append(serverName)
                    dsData.append(testResult)
                    notRunningDS.append(dsData)
                if notRunningDS:
                    completeDSList.append(notRunningDS)
        disconnect('force')
        return completeDSList
	except Exception, e:
		global	connectionError 
		connectionError = "True"
		print >> logFile, "Problem while connecting to Admin Server or Other Runtime exception !!!"
		print >> logFile, '-'*100
		print >> logFile, str(e)
		print >> logFile, '-'*100

#Please change below variable according to your env.
env = 'QA'
domain = 'ADF'
username = 'weblogic'
password = 'guessme'
URL = 't3://hostname:8001'
connectionError = ""
logLocation  = '/orabpm/app/scripts/dataSourceMonitoring/logs/log.txt'
logFile = open(logLocation,'w+')
notRunningDS = findDSStatus()
if notRunningDS is None:
	notRunningDS = []

if (connectionError != "True" and len(notRunningDS)) > 0:
	print >> logFile, "Unhealthy Datasources: "
	print >> logFile, '-'*90
 	print >> logFile, "Datasource Name\t" + "State \t \t" + "Server \t \t" + "Test Result"
	print >> logFile, '-'*90
 	for svr in notRunningDS:
		for ds in svr:
        		print >> logFile, ds[0].ljust(20)  +  "\t" +  ds[1] + "\t" + ds[2] + "\t" + ds[3]

logFile.close()
if (len(notRunningDS) > 0):
        sender = 'osUser@hostname'
        receivers = [ ] #comma separated email ids like 'abc@example.com', 'xyz@example.com'
        message = """From: hostname  <osUser@hostname> \n MIME-Version: 1.0 \n Content-type: text/html \nSubject: Alert: """ + env + " -  " + domain +  """ Datasource Alert \n"""
        logFile = open(logLocation,'r')
        message = message + logFile.read() 
        try:
                smtpObj = smtplib.SMTP('localhost')
                smtpObj.sendmail(sender, receivers, message)
        except smtplib.SMTPException:
                print >> logFile, "Error: unable to send email"