from tornado import web


class MainHandler(web.RequestHandler):
    async def get(self):
        self.write("Welcome to Performance Monitor Charts!")
        return
