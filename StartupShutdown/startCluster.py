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
 
connect(Username, Password,'t3://' + Host + ':7001')
 
clusterNames = configProps.get("cluster.names").split(",")

for cluster in clusterNames:
	print '###### clusterName = ', cluster
	start(cluster,'Cluster','t3://' + Host + ':7001',block='true')
	print ''
	print '============================================='
	print '===> Successfully started ', cluster, '  <==='
	print '============================================='
	print ''

disconnect()
