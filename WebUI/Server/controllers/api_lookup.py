import controllers.main as main
from tools.tools_data import is_int
import models.lookup as lkp


def get_id_name(id_name):
    """ Returns id, name pair for any given string. """
    id = 0
    name = ""
    if id_name is not None:
        if is_int(id_name):
            id = int(id_name)
        else:
            name = id_name
    return id, name


class LookupServerApiHandler(main.MainHandler):
    async def get(self):
        """
        self.set_status(501)
        self.write({"error": "Under construction",})
        """
        results = lkp.Lookup.get_serverlist()
        self.add_header('Access-Control-Allow-Origin', '*')
        self.write({
            "results": results.serialize() if results is not None else ""
        })
        return


class LookupMetricSetApiHandler(main.MainHandler):
    async def get(self, server_name_id):
        """ Get list of metric sets based on server name or id. """
        server_id, server_name = get_id_name(server_name_id)
        results = lkp.Lookup.get_metricsetlist(server_id, server_name)
        self.add_header('Access-Control-Allow-Origin', '*')
        self.write({
            "results": results.serialize() if results is not None else ""
        })
        return


class LookupMetricApiHandler(main.MainHandler):
    async def get(self, server_name_id, set_name_id):
        """ Get list of metric sets based on server name or id. """
        server_id, server_name = get_id_name(server_name_id)
        set_id, set_name = get_id_name(set_name_id)
        results = lkp.Lookup.get_metriclist(server_id, server_name, set_id, set_name)
        self.add_header('Access-Control-Allow-Origin', '*')
        self.write({
            "results": results.serialize() if results is not None else ""
        })
        return
