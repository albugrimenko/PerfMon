import sys
import logging
import pyodbc as sql


class RptDataAvItem:

    def __init__(self, date, values):
        self.date = date
        self.values = values

    def serialize(self):
        return {
            "date": self.date,
            "values": self.values
        }

    def serialize_compact(self):
        return [self.date, self.values]

    def serialize_formatted(self):
        return {
            "date": self.date,
            "values": "{0:t}".format(self.values)
        }


class RptDataAv(object):

    def __init__(self):
        self.header = []
        self.items = []
        self.sql_statement = "GetRpt_DataAvailability "    # SQL statement to load data
        return

    def add(self, date, values):
        if len(values)+1 != len(self.header):
            raise Exception('Values-header mismatch')
        item = RptDataAvItem(date, values)
        self.items.append(item)

    def serialize(self):
        res = []
        for x in self.items:
            item = {"date": x.date}
            for k, v in zip(self.header[1:], x.values):
                item[k] = v
            res.append(item)
        return res

    def serialize_formatted(self):
        """ Includes header as first row """
        res = self.header
        for x in self.items:
            item = {"date": x.date}
            for k, v in zip(self.header[1:], x.values):
                item[k] = v
            res.append(item)
        return res

    def load_sql(self, con_string):
        assert self.sql_statement, "SQL statement to load data is required."
        assert con_string, "Connection string is required."
        con = None
        try:
            con = sql.connect(con_string)
            cursor = con.cursor()
            cursor.execute(self.sql_statement)

            self.items = []
            self.header = [f[0] for f in cursor.description]
            row = cursor.fetchone()
            while row:
                date = row[0]
                self.add(date, row[1:])
                row = cursor.fetchone()
        except:
            logging.error("RptDataAv.load_sql" + sys.exc_info().__str__())
        finally:
            if con is not None:
                con.close()
        return
