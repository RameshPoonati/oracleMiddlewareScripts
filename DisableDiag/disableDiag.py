print 'Connecting to WLS'
connect('weblogic','password','t3://ipaddress:port')
domainConfig()
allServers=cmo.getServers();

svrs = [];
for server in allServers: #get all server names.
	svrs.append(server.getName());
disconnect()

for svr in svrs:
	connect('weblogic','password','t3://ipaddress:port')
	edit()
	startEdit()
	print 'Going to MBean tree: Servers/' + svr  + '/ServerDiagnosticConfig'
	configpath = 'Servers/' + svr + '/ServerDiagnosticConfig';
	cd(configpath)
	print 'Going to Server:' + svr;
	cd(svr)
	print 'Current WLDFBuiltinSystemResourceType Value: ' + str(cmo.getWLDFBuiltinSystemResourceType())
	print 'Disabling WLDF'
	cmo.setWLDFBuiltinSystemResourceType('None')
	print 'Current Diag volume setting: ' + str(cmo.getWLDFDiagnosticVolume());
	print 'Disabling diagnostic volume'
	cmo.setWLDFDiagnosticVolume('Off')
	activate()
	print 'Changes activated successfully'
	print '***********************************'
	print svr + ' : ' + 'WLDFBuiltinSystemResourceType value: '+ cmo.getWLDFBuiltinSystemResourceType()
	print svr + ' : ' + 'setWLDFDiagnosticVolume value: ' + cmo.getWLDFDiagnosticVolume()
	disconnect()
exit()
