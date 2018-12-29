"""
Reports factory
"""
from tools.config import ConfigJSON


class Reports(object):

    sql_constring = ""

    @staticmethod
    def is_initialized():
        return Reports.sql_constring != ""

    @staticmethod
    def init():
        cnf = ConfigJSON()
        Reports.sql_constring = cnf.get("sql_constring")
        return

    @staticmethod
    def get_dashboard():
        import models.report_dashboard_sql as dash
        if not Reports.is_initialized():
            Reports.init()
        rpt = dash.RptDashboard()
        rpt.load_sql(Reports.sql_constring)
        return rpt

    @staticmethod
    def get_dashboard_card():
        rpt = Reports.get_dashboard()
        def_cats = ["Disk", "Memory", "Network", "Processor", "SQLServer", "Other"]
        res = []
        card = {}
        n = 0
        for item in rpt.items:
            if "server_id" not in card or card["server_id"] != item.server_id or card["date"] != item.date:
                if "server_id" in card:
                    res.append(card)
                n += 1
                card = dict({"n": n})
                card["server_id"] = item.server_id
                card["server_name"] = item.server_name
                card["date"] = item.date
                card["issues"] = []

            card["issues"].append(
                {
                    "resource": item.metric_name if item.metric_name in def_cats else "Other",
                    "times": "{0}-{1} ({2})".format(item.time_start.replace(":00:00", ""),
                                                    item.time_end.replace(":00:00", ""),
                                                    item.time_int_cnt)
                }
            )

        if "server_id" in card:
            res.append(card)

        return res

if __name__ == "__main__":
    print(Reports.get_dashboard_card())
