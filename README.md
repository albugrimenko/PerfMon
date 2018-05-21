# PerfMon
Windows Performance Monitor data collection, storage and reports: power shell scrips, SQL, HTML. 

Set up Windows Performance Monitor to collect all sorts of metrics on daily basis. Run power shell script to collect data from multiple servers and store it in the centralized database. Use provided stored procs to visually present data.

All counters are grouped by Server, Metric Set and Metric. Data values averaged with 5 sec time interval.

## Credits

* Original idea, metrics collection setup and power shell implementation by **David Klee**:
[Perfmon to SQL Server Importer](http://www.heraflux.com).

* Some data structure elements, such as Date and Time dimentions and it's population, taken from the **[Adam Machanic](https://www.linkedin.com/in/adammachanic/)** seminar.

## Setup

1. SQL Server database using deployment scripts provided in the DB folder.
2. Setup performance monitor data collection on each server you want to monitor. You can set whatever counters you think are important for each server. Detailed information on how to set up monitoring is in the *Perfmon-setup-Win2008R2-and-above-20171106.pdf*
3. Make sure that data collected in the local folder and can be accessed remotely from the central server by the user you are planning to run data collection on daily basis.
4. List all servers and corresponding shared folders in the *PerfmonToSQL_AB.servers* file. Format is simple:
Server name|Remote location
5. Run power shell script to import data from all servers.

Notes: 
* All data collected by performance monitor is organized by day – all counters for a day are stored in a single file. To capture all latest data, make sure you import data for current and previous day as well, SQL stored procs expect to receive the same data many times and will not create duplicates.
* It is easy to export Windows Performance Monitor data collection settings and import them on a different server. Usually, it is helpful to have such xml file for each specific server, i.e. for SQL server, for web server and so on – server specifics may dictate what counters are important to monitor, but usually the same for each server in a group.

## Daily Routing

* Run power shell script daily/hourly or by whatever schedule you need.
* Run stored procedure srv_ComputeStats daily, to make sure that all statistics are fresh. Read “Collected metric values analysis” below for details.

## SQL Server Database

PerfmonE is an "enterprise" version of the database. It uses data partitioning to optimize performance. Table partitioning required enterprise license for MS SQL Server 2016 and earlier, but is available in all versions, including SQL Express, since SQL 2016 SP1.

Data partitioning defined by date, i.e. the most granular possible partition is 1 day/partition - data is partitioned by "DayOfYear". Current script defines partition size to 30 days and need to be edited if other partition size is desired (see file 03_Tables.sql).

There are two database roles defined:
*	*Importer* – allowed to call stored procedure to import new data
*	*Reporter* – allowed to call stored procedures to read performance counter values and corresponding lookup tables as well as all current and future reports.
In the deployment script a single user “perfmon” is added to both of those roles – modify according to your specific needs.

### Maintenance
* Run stored procedure srv_ComputeStats daily – it keeps all required data statistics fresh.
* Optimize indexes as needed.
* Based on your data retention policy, historical data may be removed from the MetricValues table. This is the only table that need monitoring and data removal. 

## Collected metric values analysis

It is important to have a baseline to compare current data to. Such baselines automatically computed every time you run stored procedure *srv_ComputeStats*. Default logic is to collect basic stats for each server-metric recorded for the last 3 weeks excluding most recent week. This default logic can easily altered by specifying Start and End dates parameters.

All basic statistics, such as mean and standard deviation, are computed for each day of week and specific time frames, which allows to capture weekly and even hourly “seasonality” of server loads. Stored procedure GetMetricValuesDet could be used as an example of the detailed report.
