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


