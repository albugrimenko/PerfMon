import sys
import logging
import pyodbc as sql


class MetricValueRawItem:
    """ Defines a raw data entry for a single metric """

    def __init__(self, date, time, value, statvalue_lo, statvalue_hi, statvalue_avg, statvalue_std):
        self.date = date
        self.time = time
        self.value = value
        self.statvalue_lo = float(statvalue_lo)
        self.statvalue_hi = float(statvalue_hi)
        self.statvalue_avg = float(statvalue_avg)
        self.statvalue_std = float(statvalue_std)

    def serialize(self):
        return {
            "date": self.date,
            "time": self.time,
            "value": self.value,
            "statvalue_lo": self.statvalue_lo,
            "statvalue_hi": self.statvalue_hi,
            "statvalue_avg": self.statvalue_avg,
            "statvalue_std": self.statvalue_std,
        }

    def serialize_compact(self):
        return [self.date, self.time, self.value,
                self.statvalue_lo, self.statvalue_hi, self.statvalue_avg, self.statvalue_std]


class MetricValueRaw(object):
    """ All raw data entries for a single metric for a specified date/time range """

    def __init__(self, start_date, end_date, server_id=0, server_name="",
                 set_id=0, set_name="", metric_id=0, metric_name=""):
        self.items = []
        #self.sql_statement = "exec GetMetricValues "    # SQL statement to load data
        self.sql_statement = "exec GetMetricValuesWithStats "  # SQL statement to load data

        param = list([
            "@StartDate='" + start_date + "'",
            "@EndDate='" + end_date + "'"
        ])

        if server_id > 0:
            param.append("@ServerID=" + str(server_id))
        elif len(server_name) > 0:
            param.append("@ServerName='" + server_name + "'")

        if set_id > 0:
            param.append("@MetricSetID=" + str(set_id))
        elif len(set_name) > 0:
            param.append("@MetricSetName='" + set_name + "'")

        if metric_id > 0:
            param.append("@MetricID=" + str(metric_id))
        elif len(metric_name) > 0:
            param.append("@MetricName='" + metric_name + "'")

        if len(param) > 0:
            self.sql_statement += ','.join(param)

        return

    def add(self, date, time, value, statvalue_lo, statvalue_hi, statvalue_avg, statvalue_std):
        item = MetricValueRawItem(
            date, time, value, statvalue_lo, statvalue_hi, statvalue_avg, statvalue_std
        )
        self.items.append(item)

    def serialize(self):
        return [x.serialize() for x in self.items]

    def serialize_compact(self):
        return [x.serialize_compact() for x in self.items]

    def load_sql(self, con_string):
        assert self.sql_statement, "SQL statement to load data is required."
        assert con_string, "Connection string is required."
        con = None
        try:
            con = sql.connect(con_string)
            cursor = con.cursor()
            cursor.execute(self.sql_statement)
            row = cursor.fetchone()
            while row:
                date, time, value, statvalue_lo, statvalue_hi, statvalue_avg, statvalue_std = row
                self.add(date, time, value, statvalue_lo, statvalue_hi, statvalue_avg, statvalue_std)
                row = cursor.fetchone()
        except:
            logging.error("MetricValueRaw.load_sql" + sys.exc_info().__str__())
        finally:
            if con is not None:
                con.close()
        return


class MetricValueDetItem:
    """ Defines a raw data entry for a single metric """

    def __init__(self, date, time_start, time_end,
                 value_lo, value_hi, value_avg, statvalue_lo, statvalue_hi, statvalue_avg, statvalue_std,
                 statratio, statratio_descr):
        self.date = date
        self.time_start = time_start
        self.time_end = time_end
        self.value_lo = float(value_lo)
        self.value_hi = float(value_hi)
        self.value_avg = float(value_avg)
        self.statvalue_lo = float(statvalue_lo)
        self.statvalue_hi = float(statvalue_hi)
        self.statvalue_avg = float(statvalue_avg)
        self.statvalue_std = float(statvalue_std)
        self.statratio = float(statratio)
        self.statratio_descr = statratio_descr

    def serialize(self):
        return {
            "date": self.date,
            "time_start": self.time_start,
            "time_end": self.time_end,
            "value_lo": self.value_lo,
            "value_hi": self.value_hi,
            "value_avg": self.value_avg,
            "statvalue_lo": self.statvalue_lo,
            "statvalue_hi": self.statvalue_hi,
            "statvalue_avg": self.statvalue_avg,
            "statvalue_std": self.statvalue_std,
            "statratio": self.statratio,
            "statratio_descr": self.statratio_descr
        }

    def serialize_compact(self):
        return [self.date, self.time_start, self.time_end,
                self.value_lo, self.value_hi, self.value_avg,
                self.statvalue_lo, self.statvalue_hi, self.statvalue_avg, self.statvalue_std,
                self.statratio, self.statratio_descr]


class MetricValueDet(object):
    """ All detailed data entries for a single metric for a specified date/time range """

    def __init__(self, start_date, end_date, server_id=0, server_name="",
                 set_id=0, set_name="", metric_id=0, metric_name=""):
        self.items = []
        self.sql_statement = "exec GetMetricValuesDet "    # SQL statement to load data

        param = list([
            "@StartDate='" + start_date + "'",
            "@EndDate='" + end_date + "'"
        ])

        if server_id > 0:
            param.append("@ServerID=" + str(server_id))
        elif len(server_name) > 0:
            param.append("@ServerName='" + server_name + "'")

        if set_id > 0:
            param.append("@MetricSetID=" + str(set_id))
        elif len(set_name) > 0:
            param.append("@MetricSetName='" + set_name + "'")

        if metric_id > 0:
            param.append("@MetricID=" + str(metric_id))
        elif len(metric_name) > 0:
            param.append("@MetricName='" + metric_name + "'")

        if len(param) > 0:
            self.sql_statement += ','.join(param)

        return

    def add(self, date, time_start, time_end,
            value_lo, value_hi, value_avg, statvalue_lo, statvalue_hi, statvalue_avg, statvalue_std,
            statratio, statratio_descr):
        item = MetricValueDetItem(
            date, time_start, time_end,
            value_lo, value_hi, value_avg, statvalue_lo, statvalue_hi, statvalue_avg, statvalue_std,
            statratio, statratio_descr
        )
        self.items.append(item)

    def serialize(self):
        return [x.serialize() for x in self.items]

    def serialize_compact(self):
        return [x.serialize_compact() for x in self.items]

    def load_sql(self, con_string):
        assert self.sql_statement, "SQL statement to load data is required."
        assert con_string, "Connection string is required."
        con = None
        try:
            con = sql.connect(con_string)
            cursor = con.cursor()
            cursor.execute(self.sql_statement)
            row = cursor.fetchone()
            while row:
                date, time_start, time_end, \
                value_lo, value_hi, value_avg, statvalue_lo, statvalue_hi, statvalue_avg, statvalue_std, \
                statratio, statratio_descr = row
                self.add(date, time_start, time_end,
                         value_lo, value_hi, value_avg, statvalue_lo, statvalue_hi, statvalue_avg, statvalue_std,
                         statratio, statratio_descr)
                row = cursor.fetchone()
        except:
            logging.error("MetricValueDet.load_sql" + sys.exc_info().__str__())
        finally:
            if con is not None:
                con.close()
        return
