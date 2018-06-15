import sys
import logging
import pyodbc as sql


class RptDashboardItem:

    def __init__(self, server_id, server_name, metric_name, date, descr, time_int_cnt, time_start, time_end):
        self.server_id = server_id
        self.server_name = server_name
        self.metric_name = metric_name
        self.date = date
        self.descr = descr
        self.time_int_cnt = time_int_cnt
        self.time_start = time_start
        self.time_end = time_end

    def serialize(self):
        return {
            "server_id": self.server_id,
            "server_name": self.server_name,
            "metric_name": self.metric_name,
            "date": self.date,
            "descr": self.descr,
            "time_intcnt": self.time_int_cnt,
            "time_start": self.time_start,
            "time_end": self.time_end
        }


class RptDashboard(object):

    def __init__(self):
        self.items = []
        self.sql_statement = "GetPotentialIssues4All @IsCompressedMode=1"    # SQL statement to load data

    def add(self, server_id, server_name, metric_name, date, descr, time_int_cnt, time_start, time_end):
        item = RptDashboardItem(
            server_id, server_name, metric_name, date, descr, time_int_cnt, time_start, time_end
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
                server_id, server_name, metric_name, date, descr, time_int_cnt, time_start, time_end = row
                self.add(server_id, server_name, metric_name, date, descr, time_int_cnt, time_start, time_end)
                row = cursor.fetchone()
        except:
            logging.error("RptDashboard.load_sql" + sys.exc_info().__str__())
        finally:
            if con is not None:
                con.close()
        return
