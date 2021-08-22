import array
from jarray import array as jarray_c
import os, datetime
import sys
from java.util import Hashtable
from java.text import SimpleDateFormat
from javax.management import MBeanServerConnection
from javax.management import ObjectName
from javax.management.openmbean import CompositeData
from javax.management.remote import JMXConnector
from javax.management.remote import JMXConnectorFactory
from javax.management.remote import JMXServiceURL
from javax.naming import Context
from java.lang import String
from java.lang import Object
from oracle.soa.management.facade import Reference
from oracle.soa.management.facade import Composite
from oracle.soa.management import CompositeDN
from oracle.soa.management.facade import ReferenceInstance
from oracle.soa.management.facade import CompositeInstance
from oracle.soa.management.facade import ComponentInstance
from oracle.soa.management.util import CompositeInstanceFilter

from oracle.soa.management.facade import Locator
from oracle.soa.management.facade import LocatorFactory
from oracle.soa.management.util import ReferenceFilter
from oracle.soa.management.util import CompositeFilter
from datetime import datetime

compositeOption = sys.argv[2]
startTime = sys.argv[3]
endTime   = sys.argv[4]

loadProperties('./env.properties')
providerURL = "t3://" + host + ":" + port + "/soa-infra";


Lines = []
if compositeOption == "ALL": # This section retrieves all composites deployed in SOA application and writes to a file.

  out = open('compositeFile.txt', 'w')
  sys.stdout = out
  sca_listDeployedComposites(host, port, username, password)
  sys.stdout = sys.__stdout__
  out.close()
  compFile = open('compositeFile.txt', 'r')
  Lines = compFile.readlines()
else: # If composite name is passed, parse it and write to file so that same code can be used for both the options.
  cmpstDetails = str("1. " + compositeOption.split("/")[1] + ", " + "partition=" +  compositeOption.split("/")[0])
  Lines.append(cmpstDetails)

mbeanRuntime = "weblogic.management.mbeanservers.runtime";
jmxProtoProviderPackages = "weblogic.management.remote";
mBeanName = "oracle.soa.config:Application=soa-infra,j2eeType=CompositeLifecycleConfig,name=soa-infra";
jndiProps = Hashtable()
jndiProps.put(Context.PROVIDER_URL, providerURL)
jndiProps.put(Context.INITIAL_CONTEXT_FACTORY,"weblogic.jndi.WLInitialContextFactory")
jndiProps.put(Context.SECURITY_PRINCIPAL, username)
jndiProps.put(Context.SECURITY_CREDENTIALS, password)

myLocator = LocatorFactory.createLocator(jndiProps)
jmxurl = "service:jmx:t3://" + host + ":" + port + "/jndi/" + mbeanRuntime
serviceURL = JMXServiceURL(jmxurl)
ht = Hashtable()
ht.put("java.naming.security.principal", username)
ht.put("java.naming.security.credentials", password)
ht.put("jmx.remote.protocol.provider.pkgs", jmxProtoProviderPackages)
jmxConnector = JMXConnectorFactory.newJMXConnector(serviceURL, ht)
jmxConnector.connect()
mbsc = jmxConnector.getMBeanServerConnection()
mbean = ObjectName(mBeanName)

cFilter = CompositeFilter(); #Composite Filter
composites = myLocator.getComposites(cFilter);
iFilter = CompositeInstanceFilter(); #Instance Filter

iFilter.setState(1)
format = SimpleDateFormat("yyyy-MM-dd HH:mm")
minDate = format.parse (startTime) 
maxDate = format.parse (endTime) 

iFilter.setMinCreationDate(minDate);
iFilter.setMaxCreationDate(maxDate);
recoveryInstCount = 0

for line in Lines:
  if (line.find('partition') != -1): #To skip header line
    lineSplit = line.split(",")
    compositeName = lineSplit[0].split()[1].split('[')[0]
    compositeVersion = lineSplit[0].split()[1].split('[')[1].split(']')[0]
    partition = lineSplit[1].split('=')[1]
    compositedn = CompositeDN(partition, compositeName, compositeVersion); # Change composite and version no.
    composite = myLocator.lookupComposite(compositedn);
    compositeInstances = composite.getInstances(iFilter);
    for compositeInstance in compositeInstances:
#      print compositeName + '	' + str(compositeVersion) + '	' + str(compositeInstance.getFlowId()) + '	' + partition + '	'  + str(compositeInstance.getCreationDate()) + '	' + str(compositeInstance.getModifyDate())
      print compositeName + '     ' + str(compositeVersion) + '     '  + partition + '     '  +  str(compositeInstance.getFlowId()) + '     ' +  str(compositeInstance.getTitle()) + '     ' + str(compositeInstance.getCreationDate()) + '     ' + str(compositeInstance.getModifyDate())
      recoveryInstCount += 1
      if sys.argv[1] == "ABORT":
 
        compositeInstance.abort()
      elif sys.argv[1] == "GET":
        continue
  else:
    continue

print "\nTotal number of instances is: " + str(recoveryInstCount) + "\n"
