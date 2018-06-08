import sys
import logging
from tornado import ioloop, web

import tools.config_helpers as cfgh
import controllers.main as cntrl_main
import controllers.api_lookup as api_lkp


DEBUG = True
PORT = 8000
ROUTES = [
    (r"/", cntrl_main.MainHandler),
    (r"/lookup/server", api_lkp.LookupServerApiHandler),
    (r"/lookup/metricset/(?P<server_name_id>\w+)?", api_lkp.LookupMetricSetApiHandler),
    (r"/lookup/metric/(?P<server_name_id>\w+)?/(?P<set_name_id>\w+)?", api_lkp.LookupMetricApiHandler),
]


def run():
    try:
        cfgh.set_logger()

        app = web.Application(
            ROUTES,
            debug=DEBUG,
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
