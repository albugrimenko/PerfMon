"""
    A simple config file accessor.
"""
import os
import json

ROOT_DIR = os.path.dirname(os.path.dirname(__file__))


class Config:
    """ Config """

    def __init__(self, filename):
        assert filename, "Filename is required."
        if not os.path.isfile(filename):
            filename = os.path.join(ROOT_DIR, filename)
            if not os.path.isfile(filename):
                raise Exception("Config file is not found: {0}.".format(filename))
        self.settings = {}
        self.filename = filename
        self.load()

    def load(self):
        """ Loads config file - reads all config parameters """
        self.settings.clear()
        return

    def get(self, paramname, default=None):
        """ Gets values of a specified paramaeter name.
            Returns default if parameter is npt found.
        """
        if paramname is None or len(paramname) == 0 \
                or self.settings is None or paramname not in self.settings.keys():
            return default
        else:
            if paramname[:4] == "dir_":
                return self.settings[paramname].format(ROOT_DIR=ROOT_DIR)
            else:
                return self.settings[paramname]


class ConfigJSON(Config):
    """ Config for json config files.
        It assumes that config file is in the root folder.
    """

    def __init__(self, filename="config.json"):
        assert filename, "filename is required."
        super().__init__(filename)

    def load(self):
        """ Loads config file - reads all config parameters """
        self.settings.clear()
        with open(self.filename) as cfg:
            self.settings = json.load(cfg)


# ---------- main calls -------------
if __name__ == "__main__":
    print("~~~ There is no Main method defined. ~~~")
