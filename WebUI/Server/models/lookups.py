"""
Lookup factory
"""
import models.lookup_sql as lkp
from tools.config import ConfigJSON


class Lookups(object):

    sql_constring = ""

    @staticmethod
    def is_initialized():
        return Lookups.sql_constring != ""

    @staticmethod
    def init():
        cnf = ConfigJSON()
        Lookups.sql_constring = cnf.get("sql_constring")
        return

    @staticmethod
    def get_serverlist():
        if not Lookups.is_initialized():
            Lookups.init()
        srvlist = lkp.LookupServerList()
        srvlist.load_sql(Lookups.sql_constring)
        return srvlist

    @staticmethod
    def get_metricsetlist(server_id=0, server_name=""):
        if not Lookups.is_initialized():
            Lookups.init()
        mslist = lkp.LookupMetricSet(server_id, server_name)
        mslist.load_sql(Lookups.sql_constring)
        return mslist

    @staticmethod
    def get_metriclist(server_id=0, server_name="", set_id=0, set_name=""):
        if not Lookups.is_initialized():
            Lookups.init()
        mslist = lkp.LookupMetric(server_id, server_name, set_id, set_name)
        mslist.load_sql(Lookups.sql_constring)
        return mslist
