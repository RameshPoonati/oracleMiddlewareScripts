from java.io import FileInputStream
import java.lang
import os
import string
 
propInputStream = FileInputStream("start.par")
configProps = Properties()
configProps.load(propInputStream)
 
Username = configProps.get("username")
Password = configProps.get("password")
Host = configProps.get("host")
nmPort = configProps.get("nm.port")
domainName = configProps.get("domain.name")
domainDir = configProps.get("domain.dir")
nmType = configProps.get("nm.type")
 
nmConnect(Username,Password,Host,nmPort,domainName,domainDir,nmType)
print ''
print '============================================='
print 'Connected to NODE MANAGER Successfully...!!!'
print '============================================='
print ''
 
serverNames = configProps.get("server.names").split(",")

for server in serverNames:
	print '###### serverName = ', server
	nmStart(server)
	print ''
	print '============================================='
	print '===> Successfully started ', server, '  <==='
	print '============================================='
	print ''

nmDisconnect()
