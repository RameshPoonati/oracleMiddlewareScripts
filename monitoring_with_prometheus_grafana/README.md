1. Install Weblogic Monitoring Exporter: Go to Weblogic Monitoring Exporter <a href="https://github.com/oracle/weblogic-monitoring-exporter/releases">github</a>  releases page and download latest get_v<version>.sh script. Copy the exporter configuration file located in this project. and pass that as parameter (e.g., ./get_v2.1.2.sh exporter_config.yaml) to get_v<version>.sh. This script downloads war file and copies configuration into war file. There is another approach, instead of packaging configuration into war file, using web interface to change the configuration. We will follow the first approach in this post. Deploy updated war file on Admin and managed servers. <br>
2. Install Prometheus & Grafana<br>
3. Configure Prometheus: Prometheus uses prometheus.yml file (usually located at: /etc/prometheus/) to get metrics source details. Sample file can be found in this project (prometheus.yml). Modify this file according to your environment (Need to mention admin server and manager server hostname and port. ) and copy to prometheus.yml. Restart Prometheus to pick latest configuration. You should be able to view metrics in Prometheus, usually at http://<hostname>:9090/graph. Metrics can also be checked from exporter web interface using url: http://serverhost:port/wls-exporter/metrics <br>
4. Configure Grafana: There are two steps here. Configuring Prometheus datasource in Grafana. This steps helps in pulling metrics data into Grafana. Please refer to <a href="https://grafana.com/docs/grafana/latest/datasources/prometheus/">official documentation</a> for the detailed steps. Second step is to configure dashboards using Prometheus metric data. Copy the dashboard configuration from this project (weblogic_grafana.json). This configuration is taken from official Weblogic Monitoring Exporter page and made minor tweaks to it. Setps to import dashboards can be found <a href="https://grafana.com/docs/grafana/v9.0/dashboards/export-import/">here</a>.  <br>
  
<b>Sample dashboard screenshots:</b>
 
<b>Overview: </b>
![Alt text](images/image1.jpg?raw=true "Sample 1")

<b>CPU and Heap Usage: </b>
![Alt text](images/image2.jpg?raw=true "Sample 2")

<b>JMS</b>
![Alt text](images/image3.jpg?raw=true "Sample 3")

Also, refer to my blog post for more inforamtion: https://sharespoint.com/monitoring-weblogic-soa-osb-using-prometheus-and-grafana/
