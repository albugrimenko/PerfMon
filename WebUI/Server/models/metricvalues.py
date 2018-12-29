"""
Metric values factory
"""
import models.metricvalues_sql as mv
from tools.config import ConfigJSON


class MetricValues(object):

    sql_constring = ""

    @staticmethod
    def is_initialized():
        return MetricValues.sql_constring != ""

    @staticmethod
    def init():
        cnf = ConfigJSON()
        MetricValues.sql_constring = cnf.get("sql_constring")
        return

    @staticmethod
    def get_rawlist(start_date, end_date, server_id=0, server_name="",
                    set_id=0, set_name="", metric_id=0, metric_name=""):
        if not MetricValues.is_initialized():
            MetricValues.init()
        mvlist = mv.MetricValueRaw(start_date, end_date, server_id, server_name,
                                   set_id, set_name, metric_id, metric_name)
        # print('-- DEBUG: {0}'.format(mvlist.sql_statement))
        mvlist.load_sql(MetricValues.sql_constring)
        return mvlist

    @staticmethod
    def get_detlist(start_date, end_date, server_id=0, server_name="",
                    set_id=0, set_name="", metric_id=0, metric_name=""):
        if not MetricValues.is_initialized():
            MetricValues.init()
        mvlist = mv.MetricValueDet(start_date, end_date, server_id, server_name,
                                   set_id, set_name, metric_id, metric_name)
        # print('-- DEBUG: {0}'.format(mvlist.sql_statement))
        mvlist.load_sql(MetricValues.sql_constring)
        return mvlist
