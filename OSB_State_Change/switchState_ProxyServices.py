# Skeleton of the script is taken from Oracle metalink.
# To run the script please do the following:
# 1) Put this file and file config.properties in the same location
# 2) Open a shell or a cmd window
# 3) Modify config.properties to reflect your environment
# 4) Run your domain setDomainEnv.cmd(.sh) script
# 5) Go back to the folder where this file is located
# 3) Run java weblogic.WLST enableDisableServices.py <servicesType> (values are proxy|business) <operation> (values are enable|disable)
#   i.e:
#       java weblogic.WLST enableDisableServices.py  business disable
#

import time as pytime
#from time import sleep as pysleep
from com.bea.wli.sb.management.configuration import SessionManagementMBean
from com.bea.wli.sb.management.configuration import ALSBConfigurationMBean
from com.bea.wli.config import Ref
from com.bea.wli.sb.util import Refs
from com.bea.wli.sb.management.configuration import CommonServiceConfigurationMBean

def setProxyStatus(proxyNames,status):
        try:
                sleepTime = 2
                sessionName  = "SetProxyStateSession_" + str(System.currentTimeMillis())
                sessionMBean = findService(SessionManagementMBean.NAME, SessionManagementMBean.TYPE)
                sessionMBean.createSession(sessionName)
                pxyConf='ProxyServiceConfiguration.' + sessionName
                mbean = findService(pxyConf, 'com.bea.wli.sb.management.configuration.ProxyServiceConfigurationMBean')
                prxNames = proxyNames.split(',')
                for aName in prxNames:
                        prxName = aName.strip()
                        proxyPath=prxName.split('/')
                        serviceRef = Ref.makeRef(Refs.PROXY_SERVICE_TYPE, proxyPath)
                        if status=='disable':
                                mbean.disableService(serviceRef)
                                print "[" + (pytime.strftime("%d/%m/%Y %H:%M:%S")) + "] " + "Disabled proxy " + prxName
                        else:
                                mbean.enableService(serviceRef)
                                print "[" + (pytime.strftime("%d/%m/%Y %H:%M:%S")) + "] " + "Enabled proxy " + prxName
                                print "[" + (pytime.strftime("%d/%m/%Y %H:%M:%S")) + "] " + "Waiting " + str(sleepTime)  + " seconds before enabling next service."
                                pytime.sleep(sleepTime)

                sessionMBean.activateSession(sessionName,status+'d '+proxyNames)
        except:
                print "[" + (pytime.strftime("%d/%m/%Y %H:%M:%S")) + "] " + "Got Error while changing status of proxy serivce"
                apply(traceback.print_exception, sys.exc_info())
                dumpStack()


print ''

if len(sys.argv) != 2:
        print "Invalid number of arguments."
        print 'Usage: switchState_ProxyServices.py <operation> [disable|enable]'
        exit()
else:
        operation=sys.argv[1]
        loadProperties('./config.properties')
        print password
        print adminHost
        print adminPort
        print userName
        print "[" + (pytime.strftime("%d/%m/%Y %H:%M:%S")) + "] " "admin host: " + adminHost
        print "[" + (pytime.strftime("%d/%m/%Y %H:%M:%S")) + "] " "admin port: " + adminPort

        connect(userName, password,'t3://'+adminHost+':'+adminPort)

        domainRuntime()

        if      operation=='disable':
                print "[" + (pytime.strftime("%d/%m/%Y %H:%M:%S")) + "] " + " Disabling Proxies ..."
                setProxyStatus(osbProxyNames,'disable')
        else:
                print "[" + (pytime.strftime("%d/%m/%Y %H:%M:%S")) + "] " + " Enabling Proxies ..."
                setProxyStatus(osbProxyNames,'enable')

print ""
print "[" + (pytime.strftime("%d/%m/%Y %H:%M:%S")) + "] " + "Finished."

