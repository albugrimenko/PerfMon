import sys
import logging
import pyodbc as sql


class LookupItem:

    def __init__(self, id, name):
        self.id = id
        self.name = name

    def serialize(self):
        return {
            "id": self.id,
            "name": self.name
        }


class Lookup(object):

    def __init__(self):
        self.items = []
        self.sql_statement = ""    # SQL statement to load data

    def add(self, id, name):
        item = LookupItem(
            id,
            name
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
                self.add(row[0], row[1])
                row = cursor.fetchone()
        except:
            logging.error("Lookup.load_sql" + sys.exc_info().__str__())
        finally:
            if con is not None:
                con.close()
        return
