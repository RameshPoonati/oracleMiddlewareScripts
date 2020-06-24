#=============================================================================================
#
# Module: Gets Application Status.
#
# Date          Author                    Description
# -----------   -------------             ------------------------------------------------
# 27/03/2019    Ramesh                    Original Version
#=============================================================================================
import smtplib
import time as pytime
import sys, traceback

def getAppStatus(): # 
        try:
                connect(username,password,url=URL,timeout=90000)
		cd ('AppDeployments')
		myapps=cmo.getAppDeployments()
 		allAppStatus = [];
		for appName in myapps:
       			domainConfig()
       			cd ('/AppDeployments/'+appName.getName()+'/Targets')
       			mytargets = ls(returnMap='true')
       			domainRuntime()
       			cd('AppRuntimeStateRuntime')
       			cd('AppRuntimeStateRuntime')
       			for targetinst in mytargets:
				appStatus = [];
             			appState=cmo.getCurrentState(appName.getName(),targetinst)
				if appState == 'STATE_ADMIN' and appName.getName().startswith('SB_JMS_Proxy'):	
					appStatus.append(appState);
					appStatus.append(appName.getName());
					allAppStatus.append(appStatus);
		

		disconnect('force')
		return(allAppStatus);
        except Exception, e:
                global  connectionError
                connectionError = "True"
		mailFlag = 'True';
                print >> mailFile, "Problem while connecting to Admin Server or Runtime exception !!"
                print >> mailFile, '-'*100
                print >> mailFile, str(e)
                print >> mailFile, '-'*100	
		sendMail()



def sendMail():

	sender = 'aosbpre@cem4sosbapre01'
	receivers = ['ramesh.poonati@specsavers.com' ]

	message = """From: """ +  sender + """ \n MIME-Version: 1.0 \n Content-type: text/html \nSubject: Alert: Action Required - """ + env + """ - JMS Proxy MDBs in ADMIN State  \n"""
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
adminApps = getAppStatus();
mailFile = open(mailLocation,'w+')

if len(adminApps) > 0:
	mailFlag = 'True';
	print >> mailFile, "\n";
	print >> mailFile, "Following JMS Proxy MDBs state changed to ADMIN.";
	print >> mailFile, "\n";
	print >> mailFile, "MDB Name \t\t\t\t\t\t\t" + "State \t";
	for dest in adminApps:
		print >> mailFile, str(dest[1]) + "\t " + str(dest[0]);

if mailFlag == 'True': #Uncomment this section to receive mail alerts.
        sendMail()
