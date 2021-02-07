#=============================================================================================
#
# Description: Monitors Weblogic/SOA/OSB Data Source health and sends an email alert.
#
# Date          Author                    Description
# -----------   -------------             ------------------------------------------------
# 11/08/2017    Ramesh Poonati            Initial Version
# 02/07/2021    Ramesh Poonati            Fix for bug
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

        		        if(testResult != 'Passed' or jdbcState != 'Running' ): 
                  			dsData.append(jdbcName)
               				dsData.append(jdbcState)
                    			dsData.append(serverName)
                    			dsData.append(testResult)
                    		  	notRunningDS.append(dsData)
        	disconnect('force')
        	return notRunningDS
	except Exception, e:
		global	connectionError 
		connectionError = "True"
		print >> logFile, "Problem while connecting to Admin Server or Other Runtime exception !!!"
		print >> logFile, '-'*100
		print >> logFile, str(e)
		print >> logFile, '-'*100

def html_table(notRunningDS,logFile):
	print >> logFile, 'Content-Type: text/html; charset="us-ascii"'
	print >> logFile, '<html>'
	print >> logFile, '<style>table {  font-family: arial, sans-serif;  border-collapse: collapse; }td, th {  border: 1px solid #dddddd;  text-align: left;  padding: 8px;}tr:nth-child(even) {  background-color: #dddddd;}</style>'
	print >> logFile, '<body  text="black">'
	print >> logFile, '<p>Following datasources are not healthy:</p>'
	print >> logFile, '<br>'
	print >> logFile, '<table>'
	print >> logFile, '<tr><th>Datasource Name</th><th>Health</th><th>Server</th><th>Test Result</th></tr>'

	for sublist in notRunningDS:
		print sublist
		print >> logFile, '  <tr><td>'
		print >> logFile, '    </td><td>'.join(sublist)
		print >> logFile, '  </td></tr>'
	print >> logFile, '</table>'
        print >> logFile, '</html>'
        print >> logFile, '</body>'
#Please change below variable according to your env.
env = 'PROD'
domain = 'SOA'
username = 'weblogic'
password = ''
URL = 't3://hostname:port'
connectionError = ""
logLocation  = '/home/oracle/scripts/dataSourceMonitoring/logs/log.txt'
logFile = open(logLocation,'w+')
notRunningDS = findDSStatus()
if notRunningDS is None:
	notRunningDS = []

if (connectionError != "True" and len(notRunningDS)) > 0:
	html_table(notRunningDS,logFile)

logFile.close()
if (len(notRunningDS) > 0):
        sender = 'osUser@hostname'
        receivers = ['ramesh_poonati@example.com' ] #comma separated email ids like 'abc@example.com', 'xyz@example.com'
        message = """From: omcscbamqykxuj  <oracle@omcscbamqykxuj> \n MIME-Version: 1.0 \n Content-type: text/html \nSubject: Action Required: """ + env + " -  " + domain +  """ Datasource Alert \n"""
        logFile = open(logLocation,'r')
        message = message + logFile.read() 
        try:
                smtpObj = smtplib.SMTP('localhost')
                smtpObj.sendmail(sender, receivers, message)
        except smtplib.SMTPException:
                print >> logFile, "Error: unable to send email"
