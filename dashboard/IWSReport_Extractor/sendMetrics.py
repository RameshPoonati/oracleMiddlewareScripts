#Description: This script parses SOA runtime metrics from IWS reports and sends them to Wavefront.
#      
# Date          Author                   Description
# --------      -------------            ------------------------------------------------
# 18/10/22      Rameshi Poonati          Initial Version
#
#========================================================================================

import xml.etree.ElementTree as ET
import pycurl, sys
from ConfigParser import SafeConfigParser

parser = SafeConfigParser()
parser.read('/home/oracle/scripts/IWSReport_Extractor/config.properties')
env = parser.get('properties', 'env') 
metrics_url = parser.get('properties', 'metrics_url') 
token = parser.get('properties', 'token')
metrics_source = parser.get('properties', 'metrics_source')
reportFile = parser.get('properties', 'tmp_dir') + "/IWSReport.xml"
logLocation = parser.get('properties', 'log_dir') + "/IWSReports.log"
logFile = open(logLocation,'a+')

try:
	report = ET.parse(reportFile)
except:
        print >> logFile, 'Error while parsing IWS reports.'
        print >> logFile, sys.exc_info()[0]
	logFile.close()
	exit()
	
root = report.getroot()
data=''

for int_qs in root.findall("./composite_stats/backup_stats/internal_queues"): #Internal bpel queue stats
	for q in int_qs.getchildren():
		q_backlog = 0
		for composite in q.getchildren():
			data = data + 'nonprod.weblogic.SOA.intQ.backlog' + ' ' +  composite.get('backlog') 
			data = data + ' ' +  'source=' +  metrics_source + ' ' + 'EnvironmentName=' +  env +  ' '  + 'QueueName=' + '"' + q.tag + '"' + ' ' + 'CompositeName=' + '"' + composite.get('name') + '"' + 'ActiveCount=' + '"' + composite.get('active') + '"' + '\n'

for composite in root.findall("./composite_stats/endpoint_stats/service/composite"): #Composite inbound stats
	data = data + 'nonprod.weblogic.SOA.inbound.latency' + ' ' +  composite.get('latency').replace(",","")
	data = data + ' ' +  'source=' + metrics_source + ' ' + 'EnvironmentName=' +  env +  ' '  + 'CompositeName=' + '"' + composite.get('name') + '"' + ' ' + 'RevisionNumber=' + '"' + composite.get('revision') + '"' + ' ' +  'Folder=' + '"' + composite.get('folder') + '"' + ' ' +  'Count=' + '"' + composite.get('interval_count') + '"' + ' ' +  'Faults=' + '"' + composite.get('interval_fault_count') + '"' + ' ' +  'TPS=' + '"' + composite.get('tps') + '"' + '\n'

for composite in root.findall("./composite_stats/endpoint_stats/reference/composite"): #Composite outbound stats
	data = data + 'nonprod.weblogic.SOA.outbound.latency' + ' ' +  composite.get('latency').replace(",","")
	data = data + ' ' +  'source=' + metrics_source + ' ' + 'EnvironmentName=' +  env +  ' '  + 'CompositeName=' + '"' + composite.get('name') + '"' + ' ' + 'RevisionNumber=' + '"' + composite.get('revision') + '"' + ' ' +  'Folder=' + '"' + composite.get('folder') + '"' + ' ' +  'Count=' + '"' + composite.get('interval_count') + '"' + ' ' +  'Faults=' + '"' + composite.get('interval_fault_count') + '"' + ' ' +  'TPS=' + '"' + composite.get('tps') + '"' + '\n'

c = pycurl.Curl()
c.setopt(pycurl.VERBOSE, True)
c.setopt(pycurl.URL, metrics_url)
headers = []
headers.append('Authorization: Bearer ' + token)
headers.append('Content-Type: text/plain')
c.setopt(pycurl.HTTPHEADER, headers)
c.setopt(pycurl.POST, 1)
c.setopt(pycurl.POSTFIELDS, data)
print >> logFile, 'Sending metrics to Wavefront ...'
c.perform()
print >> logFile, "Response Code: " + str(c.getinfo(pycurl.HTTP_CODE))
c.close()
logFile.close()
