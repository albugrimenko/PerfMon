from tornado import web
from tools.tools_data import is_int


class MainHandler(web.RequestHandler):
    async def get(self):
        self.write("Welcome to Performance Monitor Charts!")
        return

    def get_results_json(self, results):
        """ results object must be serializable """
        """
        self.set_status(501)
        self.write({"error": "Under construction",})
        """
        self.add_header('Access-Control-Allow-Origin', '*')
        self.write({
            "results": results.serialize() if results is not None else ""
        })
        return

    @staticmethod
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
