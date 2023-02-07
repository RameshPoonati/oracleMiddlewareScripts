Install jolokia and telegraf agents as per https://docs.wavefront.com/weblogic.html.
Use/replace jolokia2_weblogic.conf and telegraf.conf to quick start with.
Setup soa aws reports from weblogic console. em console -> SOA -> SOA Server Right Click -> Monitoring -> IWS Reports -> Configure. This step is not required if you are not planning to monitor SOA.
For OSB, copy GetStats directory and update configuration. Monitoring needs to be enabled in serveric bus em console.
For SOA, copy IWSReport_Extractor directory and update configuration.
Setup cron jobs for custom scripts.
Clone dashboards


Mention dir where the two files are located
Need to change urls in jolokia2_weblogic.conf
upload sample waverfront exported file to github.
