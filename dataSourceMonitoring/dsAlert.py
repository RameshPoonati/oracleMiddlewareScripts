#=============================================================================================
#
# Description: Monitors Weblogic/SOA/OSB Data Source health and sends an email alert.
#
# Date          Author                    Description
# -----------   -------------             ------------------------------------------------
# 11/08/2017    Ramesh Poonati            Initial Version
# 02/07/2021    Ramesh Poonati            Fix for bug
# 23/04/2022    Ramesh Poonati            Added functionality to capture datasources missing from runtime.
#=============================================================================================

def getClusterInfo():
	try:
		connect(user,password,url=Url,timeout=90000)
                allClusters = cmo.getClusters()
                AllClustersData = {}
                for cluster in allClusters:
			clusterData = []
			clusterName = cluster.getName()
			clusterMembers  = cluster.getServers()
			for member in clusterMembers:
				serverName = member.getName()
				clusterData.append(serverName)
			AllClustersData[clusterName] = clusterData
		return AllClustersData
        	disconnect('force')
	except Exception, e:
		global	connectionError 
		connectionError = "True"
		print >> logFile, "Problem while connecting to Admin Server or Other Runtime exception !!!"
		print >> logFile, '-'*100
		print >> logFile, str(e)
		print >> logFile, '-'*101


def getDSInfo(): #Get datasource and target inforation from configuration. 
	allDsTargets = {}
	try:
		connect(user,password,url=Url,timeout=90000)
                allJDBCResources = cmo.getJDBCSystemResources()
                for DS in allJDBCResources:
			dsTargets = []
			dsName = DS.getName()
			targets = DS.getTargets()
			if len(targets) == 0: #Ignore DS without targets.
				continue
			else:
				for target in targets:
					targetName = target.getName()
					if targetName in AllClustersData:
						dsTargets.extend(AllClustersData[targetName])
					else:
						dsTargets.append(targetName)
					
				allDsTargets[dsName] = dsTargets
		return allDsTargets
        	disconnect('force')
	except Exception, e:
		global	connectionError 
		connectionError = "True"
		print >> logFile, "Problem while connecting to Admin Server or Other Runtime exception !!!"
		print >> logFile, '-'*100
		print >> logFile, str(e)
		print >> logFile, '-'*100


def findDSStatus():
	notRunningDS = []
	try:
		connect(user,password,url=Url,timeout=90000)
		svrList=domainRuntimeService.getServerRuntimes()
		
		global runtimeDSDetails
		runtimeDSDetails = {}
		
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
                    			dsData.append(serverName)
               				dsData.append(jdbcState)
                    			dsData.append(testResult)
                    		  	notRunningDS.append(dsData)

				target = []
				target.append(serverName)
				if jdbcName not in runtimeDSDetails: #Build dictionary of runtime datasource information similar to config dict in getDSInfo().
					runtimeDSDetails[jdbcName] = target
				else:
					runtimeDSDetails[jdbcName].extend(target)
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
	print >> logFile, '<tr><th>Datasource Name</th><th>Server</th><th>Health</th><th>Test Result</th></tr>'

	for sublist in notRunningDS:
		print >> logFile, '  <tr><td>'
		print >> logFile, '    </td><td>'.join(sublist)
		print >> logFile, '  </td></tr>'
	print >> logFile, '</table>'
        print >> logFile, '</html>'
        print >> logFile, '</body>'


if __name__ != "__main__":
	import smtplib
	import os, sys, traceback
	scriptHome = os.getenv('SCRIPT_HOME')
	loadProperties(scriptHome + '/script.properties') #Please change property file according to your env
	connectionError = ""
	logFile = open(logLocation,'w+')
	notRunningDS = findDSStatus()
	AllClustersData = getClusterInfo()
	configDSDetails = getDSInfo()

	for ds in configDSDetails:
		if ds in runtimeDSDetails: #Compare runtime and config data, if something is missing write to notRunningDS list.
			configDSDetails[ds].sort()
			runtimeDSDetails[ds].sort()
			if configDSDetails[ds] == runtimeDSDetails[ds]:
				continue
	                else:
        	                missingDS = []
                	        missingDS.append(ds)
                        	missingDS.append('Missing')
                        	missingDS.append('Missing')
                        	missingDS.append('Missing')
                        	notRunningDS.append(missingDS)

		else:
			missingDS = []
			missingDS.append(ds)
			missingDS.append('Missing')
			missingDS.append('Missing')
			missingDS.append('Missing')
			notRunningDS.append(missingDS)


	if notRunningDS is None:
		notRunningDS = []

	if (connectionError != "True" and len(notRunningDS)) > 0:
		html_table(notRunningDS,logFile)

	logFile.close()
	if (len(notRunningDS) > 0):
        	message = """From:""" + sender + """\nTo:""" + receivers  + """\nMIME-Version: 1.0 \nContent-type: text/html \nSubject: """ + """Action Required: """ + env + """ - Datasource Alert \n""" # Change according to your env
	      	logFile = open(logLocation,'r')
        	message = message + logFile.read() 
		logFile.close()
		receiversList=receivers.split(',')
        	try:
                	smtpObj = smtplib.SMTP('localhost')
                	smtpObj.sendmail(sender, receiversList, message)
        	except smtplib.SMTPException:
			logFile = open(logLocation,'w+')
			print >> logFile, 'Error: unable to send email'
			logFile.close()
