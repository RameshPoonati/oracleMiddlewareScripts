Description - It contains scripts to generate daily error reports for various applications: SOA, OSB, RMQ and Kafka. This is done by parsing log files. We can easily configure script by changing values in server.list (list of servers) and script.properties (mailing list, log location etc).

Note: Configure cron job at zeroth minute and hour of every day to get dail report.