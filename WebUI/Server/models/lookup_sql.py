import models.lookup_base_sql as base


class LookupServerList(base.Lookup):

    def __init__(self):
        super().__init__()
        self.sql_statement = "exec GetServerList"


class LookupMetricSet(base.Lookup):

    def __init__(self, server_id=0, server_name=""):
        super().__init__()
        self.sql_statement = "exec GetMetricSetList"

        if server_id > 0:
            self.sql_statement += " @ServerID=" + str(server_id)
        elif len(server_name) > 0:
            self.sql_statement += " @ServerName='" + server_name + "'"


class LookupMetric(base.Lookup):

    def __init__(self, server_id=0, server_name="", set_id=0, set_name=""):
        super().__init__()
        self.sql_statement = "exec GetMetricList "

        param = []
        if server_id > 0:
            param.append("@ServerID=" + str(server_id))
        elif len(server_name) > 0:
            param.append("@ServerName='" + server_name + "'")

        if set_id > 0:
            param.append("@MetricSetID=" + str(set_id))
        elif len(set_name) > 0:
            param.append("@MetricSetName='" + set_name + "'")

        if len(param) > 0:
            self.sql_statement += ','.join(param)

        return
