import os
import sys
import logging
from tornado import ioloop, web

import tools.config_helpers as cfgh
import controllers.main as cntrl_main
import controllers.api_lookup as api_lkp
import controllers.api_report as api_rpt
import controllers.api_metricvalues as api_mv


DEBUG = True
PORT = 8000
ROUTES = [
    (r"/", cntrl_main.MainHandler),
    (r"/lookup/server", api_lkp.LookupServerApiHandler),
    (r"/lookup/metricset/(?P<server_name_id>[\w-]+)?", api_lkp.LookupMetricSetApiHandler),
    (r"/lookup/metric/(?P<server_name_id>[\w-]+)?/(?P<set_name_id>[()\w-]+)?", api_lkp.LookupMetricApiHandler),
    (r"/report/dashboard", api_rpt.ReportDahsboardApiHandler),
    (r"/report/html/dashboard", api_rpt.ReportHTMLDahsboardApiHandler),
    (r"/report/issues/(?P<server_name_id>[\w-]+)?", api_rpt.ReportIssuesApiHandler),
    (r"/report/html/issues/(?P<server_name_id>[\w-]+)?", api_rpt.ReportHTMLIssuesApiHandler),
    (r"/metricvalues/raw/(?P<server_name_id>[\w-]+)?/(?P<set_name_id>[()\w-]+)?/(?P<metric_name_id>[()\w-]+)?",
        api_mv.MetricValuesRawApiHandler),
    (r"/metricvalues/det/(?P<server_name_id>[\w-]+)?/(?P<set_name_id>[()\w-]+)?/(?P<metric_name_id>[()\w-]+)?",
        api_mv.MetricValuesDetApiHandler),
    (r"/report/dataav", api_rpt.ReportDataAvApiHandler),
    (r"/report/html/dataav", api_rpt.ReportHTMLDataAvApiHandler),
]


def run():
    try:
        cfgh.set_logger()

        app = web.Application(
            ROUTES,
            debug=DEBUG,
            template_path=os.path.join(os.path.dirname(__file__), "templates"),
        )
        app.listen(PORT)
        logging.info("-- Server (re)started. Listening on port {0} --".format(PORT))

        ioloop.IOLoop.current().start()
        ioloop.IOLoop.current().close()
    except:
        logging.error(sys.exc_info().__str__())
    finally:
        ioloop.IOLoop.clear_current()

    return


if __name__ == "__main__":
    run()
