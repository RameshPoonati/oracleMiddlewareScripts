#Description: This wlst script get OSB statistics. 
#Credits: Core script is taken from Oracle doc: 2760864.1

import time as pytime
import httplib, urllib, urllib2
from com.bea.wli.sb.management.configuration import SessionManagementMBean
from com.bea.wli.sb.management.configuration import ALSBConfigurationMBean
from java.lang import String
from com.bea.wli.config import Ref
from com.bea.wli.sb.util import Refs
from com.bea.wli.sb.management.configuration import CommonServiceConfigurationMBean
from com.bea.wli.sb.management.configuration import ProxyServiceConfigurationMBean
from com.bea.wli.monitoring import StatisticType
from com.bea.wli.monitoring import ServiceDomainMBean
from com.bea.wli.monitoring import ServiceResourceStatistic
from com.bea.wli.monitoring import StatisticValue
from com.bea.wli.monitoring import ResourceType
from com.bea.wli.monitoring import MonitoringNotEnabledException

loadProperties('/home/oracle/scripts/GetStats/config.properties')
logLocation = log_dir + "/OSBStats.log"
logFile = open(logLocation,'w+')
connect (username=username, password=password, url=URL)

domName=cmo.getName()
domainRuntime()

alsbCore = findService(ALSBConfigurationMBean.NAME, ALSBConfigurationMBean.TYPE)
allRefs = alsbCore.getRefs(Ref.DOMAIN)
stats = HashMap()
sessionBean = findService(ServiceDomainMBean.NAME, ServiceDomainMBean.TYPE)

data = ''
for ref in allRefs:
	typeId = ref.getTypeId()
	if typeId == "BusinessService":
		stats = sessionBean.getBusinessServiceStatistics([ref],ResourceType.SERVICE.value(),'')
		try:
			for rs in stats[ref].getAllResourceStatistics():
				for e in rs.getStatistics():
					if e.getType() == StatisticType.COUNT:
						if e.getName() == "failure-rate" or e.getName() == "message-count":
							data = data + 'nonprod.weblogic.OSB.BS.' + e.getName() + ' ' +  str(e.getCount()) + ' ' + 'BusinessService=' + ref.getLocalName()
							data = data + ' ' +  'source=' + metrics_source + ' ' + 'EnvironmentName=' +  env + '\n'

					if e.getType() == StatisticType.INTERVAL:
						if e.getName() == "response-time":
							data = data + 'nonprod.weblogic.OSB.BS.' + e.getName() + ' ' +  str(e.getAverage()) + ' ' + 'BusinessService=' + ref.getLocalName()
							data = data + ' ' +  'source=' + metrics_source + ' ' + 'EnvironmentName=' +  env + '\n'
		
		except MonitoringNotEnabledException:	
			print >> logFile, 'Monitoring is not enabled for BS:' + ref.getLocalName()
		except:
			print >> logFile, 'Unexpected error:' + sys.exc_info()[0]

	if typeId == "ProxyService":
		stats = sessionBean.getProxyServiceStatistics([ref],ResourceType.SERVICE.value(),'')
		try:
			for rs in stats[ref].getAllResourceStatistics():
				for e in rs.getStatistics():
					if e.getType() == StatisticType.COUNT:
						if e.getName() == "failure-rate" or e.getName() == "message-count":
							data = data + 'nonprod.weblogic.OSB.PS.' + e.getName() + ' ' +  str(e.getCount()) + ' ' + 'ProxyService=' + ref.getLocalName()
							data = data + ' ' +  'source=' + metrics_source + ' ' + 'EnvironmentName=' +  env + '\n'

					if e.getType() == StatisticType.INTERVAL:
						if e.getName() == "response-time":
							data = data + 'nonprod.weblogic.OSB.PS.' + e.getName() + ' ' +  str(e.getAverage()) + ' ' + 'ProxyService=' + ref.getLocalName()
							data = data + ' ' +  'source=' + metrics_source + ' ' + 'EnvironmentName=' +  env + '\n'
		
		except MonitoringNotEnabledException, e:	
			print >> logFile, 'Monitoring is not enabled for PS:' + ref.getLocalName()
		except:
			print >> logFile, 'Unexpected error:' + sys.exc_info()[0]

sessionBean.resetStatistics(sessionBean.getMonitoredProxyServiceRefs()) #Reset Proxy stats. As per Oracle recommendation, min frequency to reset is 15 mins to avoid prerformance issues.
sessionBean.resetStatistics(sessionBean.getMonitoredBusinessServiceRefs()) #Reset BS stats. As per Oracle recommendation, min frequency to reset is 15 mins to avoid prerformance issues.
disconnect()

method = "POST"
handler = urllib2.HTTPHandler()
opener = urllib2.build_opener(handler)
url=metrics_url
request = urllib2.Request(url, data=data)
request.add_header("Authorization", 'Bearer ' + token)
request.get_method = lambda: method

try:
	connection = opener.open(request)
except urllib2.HTTPError, e:
	if e.code == 202:
		print >> logFile, 'Metrics are sucessfully sent to wavefront.'
		pass
	else:
		print >> logFile, 'Error sending metrics to wavefront.', sys.exc_info()[0]
