#============================================================================================
#
# Description: Downloads SOA IWS Reports which can be parsed further for monitoring purposes.
#
# Date          Author                    Description
# -----------   -------------             ------------------------------------------------
# 12/10/2022    Ramesh                    Initial Version
#=============================================================================================
import smtplib
import sys, traceback
from datetime import datetime as dt
from datetime import  timedelta

loadProperties('/home/oracle/scripts/IWSReport_Extractor/config.properties')
reportFile = tmp_dir + "/IWSReport.xml"
now = dt.utcnow()
reportStartTime = now - timedelta(hours=0, minutes= int(frequency) + 1) #We may get empty report if report start time is exactly frequency mins earlier than current time. So added 1 more minute to delta.
reportEndTime = now - timedelta(hours=0, minutes=0) 

logLocation = log_dir + "/IWSReports.log"
logFile = open(logLocation,'w+')
print >> logFile, 'Report start time: ' + reportStartTime.strftime('%Y-%m-%dT%H:%M:%S-0000')
print >> logFile, 'Report end time: ' + reportEndTime.strftime('%Y-%m-%dT%H:%M:%S-0000')

connect(username,password,url=URL,timeout=90000)
try:
	getSoaIWSReportByDateTime('soa_cluster', 1, reportStartTime.strftime('%Y-%m-%dT%H:%M:%S-0000'), reportEndTime.strftime('%Y-%m-%dT%H:%M:%S-0000') , None, None, 100, 'xml', reportFile)
	print >> logFile, 'IWS reports are copied.'
except:
	print "Error"
	print >> logFile, 'Error getting IWS reports.'
	print >> logFile, sys.exc_info()[0]

logFile.close()
