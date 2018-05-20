# PerfMon
Windows Performance Monitor data collection, storage and reports: power shell scrips, SQL, HTML. 

Set up Windows Performance Monitor to collect all sorts of metrics on daily basis. Run power shell script to collect data from multiple servers and store it in the centralized database. Use provided stored procs to visually present data.

All counters are grouped by Server, Metric Set and Metric. Data values averaged with 5 sec time interval.

## Credits

* Original idea, metrics collection setup and power shell implementation by David Klee:
[Perfmon to SQL Server Importer](http://www.heraflux.com).

* Some data structure elements, such as Date and Time dimentions and it's population, taken from the [Adam Machanic](https://www.linkedin.com/in/adammachanic/) seminar.

## SQL Server Database

PerfmonE is an "enterprise" version of the database. It uses data partitioning to optimize performance. Table partitioning required enterprise license for MS SQL Server 2016 and earlier, but is available in all versions, including SQL Express, since SQL 2016 SP1.

Data partitioning defined by date, i.e. the most granular possible partition is 1 day/partition - data is partitioned by "DayOfYear". Current script defines partition size to 30 days and need to be edited if other partition size is desired (see file \PerfmonE\Scripts_Deployment\03_Tables.sql).
