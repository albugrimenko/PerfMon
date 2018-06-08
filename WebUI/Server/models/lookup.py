"""
Lookup factory
"""
import models.lookup_sql as lkp
from tools.config import ConfigJSON


class Lookup(object):

    sql_constring = ""

    @staticmethod
    def init():
        cnf = ConfigJSON()
        if Lookup.sql_constring == "":
            Lookup.sql_constring = cnf.get("sql_constring")
        return

    @staticmethod
    def get_serverlist():
        if Lookup.sql_constring == "":
            Lookup.init()
        srvlist = lkp.LookupServerList()
        srvlist.load_sql(Lookup.sql_constring)
        return srvlist

    @staticmethod
    def get_metricsetlist(server_id=0, server_name=""):
        if Lookup.sql_constring == "":
            Lookup.init()
        mslist = lkp.LookupMetricSet(server_id, server_name)
        mslist.load_sql(Lookup.sql_constring)
        return mslist

    @staticmethod
    def get_metriclist(server_id=0, server_name="", set_id=0, set_name=""):
        if Lookup.sql_constring == "":
            Lookup.init()
        mslist = lkp.LookupMetric(server_id, server_name, set_id, set_name)
        mslist.load_sql(Lookup.sql_constring)
        return mslist
