import array
from jarray import array as jarray_c
import os, datetime
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
from oracle.soa.management.util import ComponentInstanceFilter

from oracle.soa.management.facade import Locator
from oracle.soa.management.facade import LocatorFactory
from oracle.soa.management.util import ReferenceFilter
from oracle.soa.management.util import ReferenceFilter

host='' # Change according to your env
port='8001' # Change according to your env
username='weblogic' # Change according to your env
password='' # Change according to your env
providerURL = "t3://" + host + ":" + port + "/soa-infra";
print providerURL 

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

compositedn = CompositeDN("EAIUCM", "CompositeName", "1.0"); # Change composite and version no.
composite = myLocator.lookupComposite(compositedn);
filter = CompositeInstanceFilter();

format = SimpleDateFormat("yyyy-MM-dd HH:mm")
minDate = format.parse ("2019-11-06 21:00") # Change according to your need
maxDate = format.parse ("2019-11-06 21:25") # Change according to your need

print minDate
print maxDate

filter.setMinCreationDate(minDate);
filter.setMaxCreationDate(maxDate);

compositeInstances = composite.getInstances(filter);
componentInstanceFilter =  ComponentInstanceFilter ();

auditDir = os.path.join(os.getcwd(), datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S'))
os.makedirs(auditDir)
#print compositeInstances
for inst in compositeInstances:
	#print inst.getAuditTrail()
	#print inst.getECID()
	listComponentInstance = inst.getChildComponentInstances(componentInstanceFilter)
#	print type(listComponentInstance)
	print listComponentInstance
#	print len(listComponentInstance)
	fileName = listComponentInstance[0].getECID();
	auditFile = open(os.path.join(auditDir, fileName), 'w')
	auditFile.writelines(listComponentInstance[0].getAuditTrail())
	auditFile.close()
#	print	listComponentInstance[0].getAuditTrail()
