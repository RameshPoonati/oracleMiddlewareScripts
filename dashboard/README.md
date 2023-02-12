1. Install jolokia and telegraf agents as per https://docs.wavefront.com/weblogic.html.<br>
2. Use/replace jolokia2_weblogic.conf (usually located at: /etc/telegraf/telegraf.d) and telegraf.conf to quick start with.<br>
3. Setup soa aws reports from weblogic console. em console -> SOA -> SOA Server Right Click -> Monitoring -> IWS Reports -> Configure. This step is not required if you are not planning to monitor SOA. <br>
4. For OSB, copy GetStats directory and update configuration. Monitoring needs to be enabled in serveric bus em console.<br>
5. For SOA, copy IWSReport_Extractor directory and update configuration.<br>
6. Setup cron jobs for custom scripts.<br>
7. Clone dashboards using sample dashboard configurations. <br> 

<b>Sample Dashboards: </b>

<b>System, JVM and Thread Pool Metrics: </b>
![Alt text](images/image1.jpg?raw=true "Sample 1")

<b>Datasource, JMS and SOA Metrics: </b>
![Alt text](images/image2.jpg?raw=true "Sample 2")

<b>OSB Metrics: </b>
![Alt text](images/image3.jpg?raw=true "Sample 3")
