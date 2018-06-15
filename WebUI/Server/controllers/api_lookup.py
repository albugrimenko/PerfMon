import controllers.main as main
import models.lookups as lkp


class LookupServerApiHandler(main.MainHandler):
    async def get(self):
        results = lkp.Lookups.get_serverlist()
        super().get_results_json(results)
        return


class LookupMetricSetApiHandler(main.MainHandler):
    async def get(self, server_name_id):
        """ Get list of metric sets based on server name or id. """
        server_id, server_name = super().get_id_name(server_name_id)
        results = lkp.Lookups.get_metricsetlist(server_id, server_name)
        super().get_results_json(results)
        return


class LookupMetricApiHandler(main.MainHandler):
    async def get(self, server_name_id, set_name_id):
        """ Get list of metric sets based on server name or id. """
        server_id, server_name = super().get_id_name(server_name_id)
        set_id, set_name = super().get_id_name(set_name_id)
        results = lkp.Lookups.get_metriclist(server_id, server_name, set_id, set_name)
        super().get_results_json(results)
        return
