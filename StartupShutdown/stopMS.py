from java.io import FileInputStream
import java.lang
import os
import string
 
propInputStream = FileInputStream("stop.par")
configProps = Properties()
configProps.load(propInputStream)
 
Username = configProps.get("username")
Password = configProps.get("password")
Host = configProps.get("host")
 
connect(Username, Password,'t3://' + Host + ':7001')
domainRuntime() 
serverNames = configProps.get("server.names").split(",")

for server in serverNames:
	print '###### serverName = ', server
	shutdown(server,'Server','true',1000,force='true', block='true')
	print ''
	print '============================================='
	print '===> Successfully Shutdown ', server, '  <==='
	print '============================================='
	print ''

