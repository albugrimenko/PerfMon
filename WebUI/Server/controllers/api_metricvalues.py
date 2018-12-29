from datetime import date
import controllers.main as main
import models.metricvalues as mv


class MetricValuesRawApiHandler(main.MainHandler):
    async def get(self, server_name_id, set_name_id, metric_name_id):
        # default output format
        fmt = self.get_query_argument("fmt", "json")

        # start_date, end_date are coming as optional query parameters sd and ed.
        # default value is today.
        sd = self.get_query_argument("sd", str(date.today()))
        ed = self.get_query_argument("ed", str(date.today()))
        start_date = super().get_date(sd, str(date.today()))
        end_date = super().get_date(ed, str(date.today()))

        server_id, server_name = super().get_id_name(server_name_id)
        set_id, set_name = super().get_id_name(set_name_id)
        metric_id, metric_name = super().get_id_name(metric_name_id)

        # print('-- DEBUG: server is {0} [{1}]'.format(server_name, server_id))
        # print('-- DEBUG: metric set is {0} [{1}]'.format(set_name, set_id))
        # print('-- DEBUG: metric is {0} [{1}]'.format(metric_name, metric_id))
        # print('-- DEBUG: from {0} to {1}'.format(start_date, end_date))

        results = mv.MetricValues.get_rawlist(start_date, end_date, server_id, server_name,
                                              set_id, set_name, metric_id, metric_name)
        if fmt == "compact":
            super().get_results_compact(results)
        else:
            super().get_results_json(results)
        return


class MetricValuesDetApiHandler(main.MainHandler):
    async def get(self, server_name_id, set_name_id, metric_name_id):
        # default output format
        fmt = self.get_query_argument("fmt", "json")

        # start_date, end_date are coming as optional query parameters sd and ed.
        # default value is today.
        sd = self.get_query_argument("sd", str(date.today()))
        ed = self.get_query_argument("ed", str(date.today()))
        start_date = super().get_date(sd, str(date.today()))
        end_date = super().get_date(ed, str(date.today()))

        server_id, server_name = super().get_id_name(server_name_id)
        set_id, set_name = super().get_id_name(set_name_id)
        metric_id, metric_name = super().get_id_name(metric_name_id)

        results = mv.MetricValues.get_detlist(start_date, end_date, server_id, server_name,
                                              set_id, set_name, metric_id, metric_name)
        if fmt == "compact":
            super().get_results_compact(results)
        else:
            super().get_results_json(results)
        return
