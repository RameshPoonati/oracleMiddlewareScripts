#=============================================================================================
#
# Module: Weblogic Thread Count Monitoring Script 
#
# Date          Author                    Description
# -----------   -------------             ------------------------------------------------
# 09/11/2018    Ramesh                    Original Version
#=============================================================================================
import smtplib
import sys, traceback

def monitorThreads():

	connect('weblogic',password,url=URL,timeout=90000)
	serverNames = getRunningServerNames()      
	domainRuntime()       

	threadCount = [];
	for name in serverNames:           
		tempCount = [];
		try:          
			cd('/ServerRuntimes/' + name.getName() + '/ThreadPoolRuntime/ThreadPoolRuntime')
		except WLSTException,e:               
			pass           
		
		tempCount.append(name.getName());
		tempCount.append(cmo.getExecuteThreadTotalCount());
		threadCount.append(tempCount);
	return threadCount;

def getRunningServerNames():   
	domainConfig()   
	return cmo.getServers()

if __name__== "main":   

	env = 'PRE-OSB'
	URL = 't3://10.243.160.27:7001'
	password='pre0sb@welc0me1'
	connectionError = ""
	logLocation  = '/home/aosbpre/scripts/ThreadMon/logs/log.txt'
	logFile = open(logLocation,'w+')
	threadCount = monitorThreads()	
	
	threshold = 20 
	for svr in threadCount:
		if svr[1] > threshold:
			print  svr[0] + " has "  +  svr[0] + " threads. "
			print >> logFile, svr[0] + " has "  +  svr[0] + " threads. "

	logFile.close()

