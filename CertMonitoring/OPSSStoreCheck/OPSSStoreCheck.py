#============================================================================================
#
# Description: This script finds opss/kss keystore certificates that are going to expire.
#
# Date          Author                    Description
# -----------   -------------             ---------------------------------------------------
# 08/11/2020    Ramesh Poonati            Initial Version
#=============================================================================================

from datetime import datetime, timedelta
import java.text.SimpleDateFormat  
import java.util.Date

def getCertDetails():
    connect(username,password,url=connectionUrl,timeout=connectionTimeout)

    #listExpiringCertificates command writes to stdout. Below block of commands redirets stdout to a file & reverts stdout to original value.
    orig_stdout = sys.stdout
    expiringCertsFile = open('logs/expiringCerts.txt', 'w')
    sys.stdout = expiringCertsFile
    svc = getOpssService(name='KeyStoreService')
    svc.listExpiringCertificates(days=alertDays, autorenew=false)
    sys.stdout = orig_stdout
    expiringCertsFile.close()
    disconnect()

def processCertInfo():
    certInfo = { }
    dtFormat = SimpleDateFormat("E MMM dd HH:mm:ss yyyy")
    logFile = open("logs/cert.log","w")
    for line in open('logs/expiringCerts.txt'):
       if 'App Stripe' in line:
           certInfo['appStripe'] = line.split('=')[1].strip()
       if 'Keystore' in line:
           certInfo['keystore'] = line.split('=')[1].strip()
       if 'Alias' in line:
           certInfo['alias'] = line.split('=')[1].strip()
       if 'Certificate status' in line:
           certInfo['status'] = line.split('=')[1].strip()
       if 'Expiration Date' in line:    #Expiration Date record marks the end of certificate info. Below block processes currrent cert.
           certInfo['expiryDt'] = line.split('=')[1].strip()
           expiryDtFmtd = str(certInfo['expiryDt']).replace("UTC ", "") # Removes UTC from date string to build date object.
           expiryDtObj = dtFormat.parse(expiryDtFmtd)
	   currDtObj =  Date() #Get current date.
           timeDiff = expiryDtObj.getTime() - currDtObj.getTime()
           daysBetween = (timeDiff / (1000*60*60*24))
           if daysBetween >= 0 and daysBetween <= int(alertDays) and certInfo['keystore'] in keystoresList and certInfo['alias'] not in certAliasExcptList: #Only concerned about keystores mentioned in the properties file.
               logFile.write("Certificate in app stripe \"" + certInfo['appStripe'] + "\" and keystore \"" + certInfo['keystore'] + "\" with alias name \"" + certInfo['alias'] + "\" is expiring on " + certInfo['expiryDt'] + "\n")
               logFile.write("\n")
           
           certInfo = { }
    logFile.close()

#Execution begins here.
cert_alias_excpt = ''
loadProperties('./config.properties')
keystoresList = keystores.split(',') # Get keystores that need be checked.
certAliasExcptList = cert_alias_excpt.split(',') # Get certificate exceptions. It helps in ignoring unimportant expiring cets.
getCertDetails()
processCertInfo()  
