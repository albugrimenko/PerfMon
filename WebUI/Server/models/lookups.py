"""
Lookup factory
"""
import models.lookup_sql as lkp
from tools.config import ConfigJSON


class Lookups(object):

    sql_constring = ""

    @staticmethod
    def init():
        cnf = ConfigJSON()
        if Lookups.sql_constring == "":
            Lookups.sql_constring = cnf.get("sql_constring")
        return

    @staticmethod
    def get_serverlist():
        if Lookups.sql_constring == "":
            Lookups.init()
        srvlist = lkp.LookupServerList()
        srvlist.load_sql(Lookups.sql_constring)
        return srvlist

    @staticmethod
    def get_metricsetlist(server_id=0, server_name=""):
        if Lookups.sql_constring == "":
            Lookups.init()
        mslist = lkp.LookupMetricSet(server_id, server_name)
        mslist.load_sql(Lookups.sql_constring)
        return mslist

    @staticmethod
    def get_metriclist(server_id=0, server_name="", set_id=0, set_name=""):
        if Lookups.sql_constring == "":
            Lookups.init()
        mslist = lkp.LookupMetric(server_id, server_name, set_id, set_name)
        mslist.load_sql(Lookups.sql_constring)
        return mslist
