"""
Helper functions to parse, analyze and print discovered data.
"""
import datetime
from dateutil.parser import parse


# ------------ Data Audit -----------
def is_int(v):
    try:
        int(v)
        return True
    except ValueError:
        return False


def is_float(v):
    try:
        float(v)
        return True
    except ValueError:
        return False


def is_date(v):
    try:
        if v is None:
            return None
        v = v.strip()
        return parse(v) is not None
    except ValueError:
        return False


def is_any_numbers(l):
    """ checks if there are at least one number available in the l """
    if l is None or len(l) < 1:
        return False
    res = [x for x in l if x is not None and is_float(x)]    # (is_int(x) or is_float(x))
    return len(res) > 0


def get_type(v):
    v = v.strip()
    if v == 'NULL':
        return type(None)
    elif v == '':
        return type(None)
    elif v.startswith('{'):
        return type([])
    elif is_int(v):
        return type(1)
    elif is_float(v):
        return type(1.1)
    elif is_date(v):
        return type(datetime.datetime)
    else:
        return type("")


def get_date(v):
    try:
        if v is None:
            return None
        v = v.strip()
        return parse(v)
    except ValueError:
        return None


def get_float(v):
    try:
        if v is None:
            return None
        v = v.strip()
        # if v.lower() == 'inf':
        #    return None
        return float(v)
    except ValueError:
        return None


# ---------- main calls -------------
if __name__ == "__main__":
    print("~~~ There is no Main method defined. ~~~")
