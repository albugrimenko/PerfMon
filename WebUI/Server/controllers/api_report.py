from datetime import date
import controllers.main as main
import models.reports as rpt


class ReportDahsboardApiHandler(main.MainHandler):
    async def get(self):
        results = rpt.Reports.get_dashboard()
        super().get_results_json(results)
        return


class ReportHTMLDahsboardApiHandler(main.MainHandler):
    async def get(self):
        results = rpt.Reports.get_dashboard_card()
        self.add_header('Access-Control-Allow-Origin', '*')
        self.render("rpt_dashboard.html", items=results)
        # self.write("<div>TESTING</div>")
        return


class ReportIssuesApiHandler(main.MainHandler):
    async def get(self, server_name_id):
        # start_date, end_date are coming as optional query parameters sd and ed.
        # default value is today.
        sd = self.get_query_argument("sd", str(date.today()))
        ed = self.get_query_argument("ed", str(date.today()))
        start_date = super().get_date(sd, str(date.today()))
        end_date = super().get_date(ed, str(date.today()))

        server_id, server_name = super().get_id_name(server_name_id)
        results = rpt.Reports.get_issues(server_id=server_id, server_name=server_name,
                                         start_date=start_date, end_date=end_date)
        super().get_results_json(results)
        return


class ReportHTMLIssuesApiHandler(main.MainHandler):
    async def get(self, server_name_id):
        # start_date, end_date are coming as optional query parameters sd and ed.
        # default value is today.
        sd = self.get_query_argument("sd", str(date.today()))
        ed = self.get_query_argument("ed", str(date.today()))
        start_date = super().get_date(sd, str(date.today()))
        end_date = super().get_date(ed, str(date.today()))
        server_id, server_name = super().get_id_name(server_name_id)

        results = rpt.Reports.get_issues(server_id=server_id, server_name=server_name,
                                         start_date=start_date, end_date=end_date)
        data = [x.serialize_formatted() for x in results.items]

        self.add_header('Access-Control-Allow-Origin', '*')
        self.render("rpt_issues.html", items=data)
        # self.write("<div>TESTING</div>")
        return
