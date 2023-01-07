#=============================================================================================
#
# Description: Monitors Weblogic/SOA/OSB Data Source health and sends an email alert.
#
# Date          Author                    Description
# -----------   -------------             ------------------------------------------------
# 11/08/2017    Ramesh Poonati            Initial Version
# 02/07/2021    Ramesh Poonati            Fix for bug
# 16/12/2022    Ramesh Poonati            Added reset logic. Included error and url details in alert.
#=============================================================================================

def getClusterInfo(): #Gets server part of a cluster.
	try:
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
	except Exception, e:
		print >> errorLogFile, "Error occurred while getting Cluster Info !!!"
		print >> errorLogFile, '-'*100
		print >> errorLogFile, str(e)
		print >> errorLogFile, '-'*100
		return {}

def getDSConfig(): #Get datasource and target inforation from configuration. 
	allDsTargets, allDsURLs  = {}, {}
	try:
                allJDBCResources = cmo.getJDBCSystemResources()
                for DS in allJDBCResources:
			dsTargets = []
			dsName = DS.getName()
			targets = DS.getTargets()
			allDsURLs[dsName] = DS.getJDBCResource().getJDBCDriverParams().getUrl()
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
		return allDsTargets, allDsURLs
	except Exception, e:
		print >> errorLogFile, "Error occurred while getting datasource configuration !!!"
		print >> errorLogFile, '-'*100
		print >> errorLogFile, str(e)
		print >> errorLogFile, '-'*100
		return {}, {}

def findDSStatus():
	def resetDS(jdbcState):
		try:
			if jdbcState == 'Shutdown':
				ds.start()
			elif jdbcState == 'Suspended':
				ds.reset()
			elif jdbcState == 'Running':
				ds.reset()
		except Exception, e:
			print >> errorLogFile, "Encountered error while resetting datasource: " + ds.getName() 
			print >> errorLogFile, '-'*100
			print >> errorLogFile, str(e)
			print >> errorLogFile, '-'*100
		
	notRunningDS = []
	try:
		svrList=domainRuntimeService.getServerRuntimes()
		restart_log = []
		runtimeDSDetails = {}
		runningServers = []	
		for server in svrList:
			serverName=server.getName()
			runningServers.append(serverName)
			jdbcRuntime=server.getJDBCServiceRuntime()
			jdbcDSlist=jdbcRuntime.getJDBCDataSourceRuntimeMBeans()
	
			for ds in jdbcDSlist:
				retry_count = 0
				dsData = []
				jdbcName=ds.getName()
      				jdbcState=ds.getState()

				while jdbcState != 'Running' and retry_count < max_retry:
					restart_log.append("Datasource " + jdbcName + "is in " + jdbcState + " state. " + "Restarting/resetting to fix it...")
					resetDS(jdbcState)
      					jdbcState=ds.getState()
					retry_count += 1

				testResult = ds.testPool()
				retry_count = 0
				while testResult is not None and retry_count < max_retry:
					restart_log.append("Datasource " + jdbcName + "test failed. " + "Restarting/resetting to fix it...")
					resetDS(jdbcState)
      					jdbcState=ds.getState()
					testResult = ds.testPool()
					retry_count += 1

				if testResult is not None:
					testResult = 'Failed: ' + testResult
				else:
					testResult = 'Passed'

				if(testResult != 'Passed' or jdbcState != 'Running' ): 
                  			dsData.append(jdbcName)
                    			dsData.append(serverName)
               				dsData.append(jdbcState)
                    			dsData.append(testResult)
                    		  	notRunningDS.append(dsData)

				target = [serverName]
				if jdbcName not in runtimeDSDetails: #Build dictionary of runtime datasource information similar to config dict in getDSConfig().
					runtimeDSDetails[jdbcName] = target
				else:
					runtimeDSDetails[jdbcName].extend(target)
        	return runtimeDSDetails, notRunningDS, runningServers, restart_log

	except Exception, e:
		print >> errorLogFile, "Error occurred while getting datasource runtime information !!!"
		print >> errorLogFile, '-'*100
		print >> errorLogFile, str(e)
		print >> errorLogFile, '-'*100
		return [], [], [], []

def addMissingDS(notRunningDS): #Adding missing runtime DS info. This situation happens when the DB is not available during server startup.

	for ds in ds_targets: #Compare runtime and config data, if something is missing write to notRunningDS list.
		if ds in runtimeDSDetails: 
			ds_targets[ds].sort()
			runtimeDSDetails[ds].sort()
			if ds_targets[ds] == runtimeDSDetails[ds]:
				continue
	                else:
        	                missingDS = []
                	        missingDS.append(ds)
                        	missingDS.append(str([ target for target in ds_targets[ds]  if target not in runtimeDSDetails[ds] ]))
                        	missingDS.append('Missing')
                        	missingDS.append('Missing')
                        	notRunningDS.append(missingDS)
				#status = retarget_DS(ds)
				#if status == 'Success':
				#	continue
				#else:
        	                #	missingDS = []
                	        # 	missingDS.append(ds)
                        	#	missingDS.append(str([ target for target in ds_targets[ds]  if target not in runtimeDSDetails[ds] ]))
                        	#	missingDS.append('Missing')
                        	#	missingDS.append('Missing')
                        	#	notRunningDS.append(missingDS)
		else:
			missingDS = []
			missingDS.append(ds)
#                        missingDS.append(str(ds_targets[ds]))
                        missingDS.append(', '.join(ds_targets[ds]))
			missingDS.append('Missing')
			missingDS.append('Missing')
			notRunningDS.append(missingDS)
			#status = retarget_DS(ds)
			#if status == 'Success':
			#	continue
			#else:
			#	missingDS = []
			#	missingDS.append(ds)
                        #	missingDS.append(str(ds_targets[ds]))
			#	missingDS.append('Missing')
			#	missingDS.append('Missing')
			#	notRunningDS.append(missingDS)


def retarget_DS(DSName): #use this function with care. If activation fails after removing targets, targets will be permanently removed from config and there will be any alerts in next run.
	edit()
	startEdit()
	cd ('/JDBCSystemResources/'+ DSName)
	target_name = get('Targets')
	try:
		set('Targets',jarray.array([], ObjectName))
		save()
		activate()
		edit()
		startEdit()
		set('Targets',target_name)
		save()
		activate()
		return 'Success'
	except Exception, e:
		cancelEdit('y')
		print >> errorLogFile, "Error occurred while retargetting datasource !!!"
		print >> errorLogFile, '-'*100
		print >> errorLogFile, str(e)
		print >> errorLogFile, '-'*100
	

def html_table(notRunningDS, restart_log, logFile):
	if len(notRunningDS) > 0:
		print >> logFile, 'Content-Type: text/html; charset="us-ascii"'
		print >> logFile, '<html>'
		print >> logFile, '<style>table {  font-family: arial, sans-serif;  border-collapse: collapse; }td, th {  border: 1px solid #dddddd;  text-align: left;  padding: 8px;}tr:nth-child(even) {  background-color: #dddddd;}</style>'
		print >> logFile, '<body  text="black">'
		print >> logFile, '<p>Following datasources are not healthy:</p>'
		print >> logFile, '<br>'
		print >> logFile, '<table>'
		print >> logFile, '<tr><th>Datasource Name</th><th>Server</th><th>Health</th><th>Test Result</th><th>Connection URL</th></tr>'

		for sublist in notRunningDS:
			print >> logFile, '  <tr><td>'
			print >> logFile, '    </td><td>'.join(sublist)
			print >> logFile, '  </td></tr>'

		print >> logFile, '</table>'

	if len(restart_log) > 0:
		print >> logFile, '<br><b>Restart log: </b><br>'
		row_number = 1
		for message in restart_log:
			print >> logFile, '<br>' + str(row_number) + '. ' + message + '<br>'
			row_number += 1
		
        print >> logFile, '</html>'
        print >> logFile, '</body>'

if __name__ != "__main__":
	import smtplib
	import sys, os, traceback
	import time as pytime
	property_file = sys.argv[1]
	runtimeDSDetails, AllClustersData, notRunningDS, runningServers, restart_log, ds_targets, dsUrls = {}, {}, [], [], [], {}, {}
	loadProperties(property_file)
	logFile = open(logLocation,'w+')
	errorLogFile = open(errorLogLocation,'w+')
	try:
		connect(user,password,url=Url,timeout=90000)
		runtimeDSDetails, notRunningDS, runningServers, restart_log = findDSStatus()
		AllClustersData = getClusterInfo()
		ds_targets, dsUrls  = getDSConfig()
		addMissingDS(notRunningDS)
		disconnect('force')
	except Exception, e:
		print >> errorLogFile, "Error occurred while creating connection or getting datasource info !!!"
		print >> errorLogFile, '-'*100
		print >> errorLogFile, str(e)
		print >> errorLogFile, '-'*100

	for ds in ds_targets: #Remove shutdown servers from targets to avoid false positives. It is expected that DS will not be available when target server is down.
		ds_targets[ds] = [ target for target in ds_targets[ds]  if target in runningServers ]
		if ds_targets[ds] == []:
			ds_targets.pop(ds)

	for ds in notRunningDS: #Add url details.
		ds.append(dsUrls[ds[0]])

	if len(notRunningDS) > 0 or len(restart_log) > 0:
		html_table(notRunningDS, restart_log, logFile)

#Send alert
	if (len(notRunningDS) > 0) or (len(restart_log) > 0) or (os.path.getsize(errorLogLocation) > 0):
        	message = """From:""" + sender + """\nTo:""" + receivers  + """\nMIME-Version: 1.0 \nContent-type: text/html \nSubject: """ # Change according to your env
		if len(notRunningDS) > 0 or os.path.getsize(errorLogLocation) > 0:
			message += """Action Required: """ + env + """ - Datasource Alert \n"""
		else:
			message += """Info: """ + env + """ - Datasources are restarted \n"""

		logFile.seek(0)
		errorLogFile.seek(0)
        	message += logFile.read() 
		if os.path.getsize(errorLogLocation) > 0:
			message += '<br><b>Error Log: </b><br>'
        		message += errorLogFile.read() 
		receiversList=receivers.split(',')
        	try:
                	smtpObj = smtplib.SMTP('localhost')
                	smtpObj.sendmail(sender, receiversList, message)
        	except smtplib.SMTPException:
			print >> logFile, 'Error: unable to send email'
	logFile.close()
	errorLogFile.close()
