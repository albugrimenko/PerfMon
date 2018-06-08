"""
    Basic check for all required libraries.
    NOTE: must be modified for the needs of each specific project.
"""

import sys
import importlib


def check_lib(lib_name):
    """ Checks if a specified library is installed. """
    res = False
    # print("... checking for {0} ...".format(lib_name))
    try:
        # import lib_name
        mod = importlib.import_module(lib_name)
        ver = ""
        if hasattr(mod, "__version__"):
            ver = " v." + getattr(mod, "__version__")
        print("+++ {0} ... OK {1}".format(lib_name, ver))
        res = True
    except ImportError:
        print("--! ERROR (checking {0}): {1}".format(lib_name, sys.exc_info()[1]))
    except:
        print("--! ERROR (checking {0}): {1}".format(lib_name, sys.exc_info()))
    return res


def check_required_libs():
    print('+++ Python: {}'.format(sys.version))

    """ Checks all required libraries """
    check_lib("json")   # used in config_json
    check_lib("time")
    check_lib("datetime")

    check_lib("pyodbc")
    check_lib("tornado")


if __name__ == "__main__":
    check_required_libs()
