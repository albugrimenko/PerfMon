import sys
import logging
import pyodbc as sql


class RptIssuesItem:

    def __init__(self, date, time_start, time_end,
                 server_id, set_id, metric_id, server_name, set_name, metric_name,
                 value_lo, value_hi, value_avg, statvalue_lo, statvalue_hi, statvalue_avg, statvalue_std,
                 statratio, statratio_descr
                 ):
        self.date = date
        self.time_start = time_start
        self.time_end = time_end
        self.server_id = server_id
        self.set_id = set_id
        self.metric_id = metric_id
        self.server_name = server_name
        self.set_name = set_name
        self.metric_name = metric_name
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
            "server_id": self.server_id,
            "set_id": self.set_id,
            "metric_id": self.metric_id,
            "server_name": self.server_name,
            "set_name": self.set_name,
            "metric_name": self.metric_name,
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
                self.server_id, self.set_id, self.metric_id, self.server_name, self.set_name, self.metric_name,
                self.value_lo, self.value_hi, self.value_avg,
                self.statvalue_lo, self.statvalue_hi, self.statvalue_avg, self.statvalue_std,
                self.statratio, self.statratio_descr]

    def serialize_formatted(self):
        return {
            "date": self.date,
            "time_start": self.time_start,
            "time_end": self.time_end,
            "server_id": self.server_id,
            "set_id": self.set_id,
            "metric_id": self.metric_id,
            "server_name": self.server_name,
            "set_name": self.set_name,
            "metric_name": self.metric_name,
            "value_lo": "{0:.4f}".format(self.value_lo),
            "value_hi": "{0:.4f}".format(self.value_hi),
            "value_avg": "{0:.4f}".format(self.value_avg),
            "statvalue_lo": "{0:.4f}".format(self.statvalue_lo),
            "statvalue_hi": "{0:.4f}".format(self.statvalue_hi),
            "statvalue_avg": "{0:.4f}".format(self.statvalue_avg),
            "statvalue_std": "{0:.4f}".format(self.statvalue_std),
            "statratio": "{0:.4f}".format(self.statratio),
            "statratio_descr": self.statratio_descr
        }


class RptIssues(object):

    def __init__(self, server_id=0, server_name="", start_date="", end_date="",
                 set_id=0, set_name="", metric_id=0, metric_name=""):
        self.items = []
        self.sql_statement = "GetPotentialIssues "    # SQL statement to load data

        param = list()
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

        if len(start_date) > 0 and len(end_date) > 0:
            param.append("@StartDate='" + start_date + "'")
            param.append("@EndDate='" + end_date + "'")

        if len(param) > 0:
            self.sql_statement += ','.join(param)
        return

    def add(self, date, time_start, time_end,
            server_id, set_id, metric_id, server_name, set_name, metric_name,
            value_lo, value_hi, value_avg, statvalue_lo, statvalue_hi, statvalue_avg, statvalue_std,
            statratio, statratio_descr):
        item = RptIssuesItem(
            date, time_start, time_end,
            server_id, set_id, metric_id, server_name, set_name, metric_name,
            value_lo, value_hi, value_avg, statvalue_lo, statvalue_hi, statvalue_avg, statvalue_std,
            statratio, statratio_descr
        )
        self.items.append(item)

    def serialize(self):
        return [x.serialize() for x in self.items]

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
                date, time_start, time_end, server_id, set_id, metric_id, server_name, set_name, metric_name, \
                    value_lo, value_hi, value_avg, statvalue_lo, statvalue_hi, statvalue_avg, statvalue_std, \
                    statratio, statratio_descr = row
                self.add(date, time_start, time_end,
                         server_id, set_id, metric_id, server_name, set_name, metric_name,
                         value_lo, value_hi, value_avg, statvalue_lo, statvalue_hi, statvalue_avg, statvalue_std,
                         statratio, statratio_descr)
                row = cursor.fetchone()
        except:
            logging.error("RptIssues.load_sql" + sys.exc_info().__str__())
        finally:
            if con is not None:
                con.close()
        return
