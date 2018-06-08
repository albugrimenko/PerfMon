import logging
from logging.handlers import TimedRotatingFileHandler
from tools.config import ConfigJSON


def set_logger(path="", level=logging.INFO):
    """ Sets logger settings """
    # general settings
    logging.basicConfig(
        format='%(asctime)s|%(levelname)s|%(message)s',
        datefmt='%Y-%m-%d %H:%M:%S')

    # daily rotating log
    if not path:
        cnf = ConfigJSON()
        path = cnf.get("dir_log") + "perfmoncharts.log"

    logger = logging.getLogger()
    logger.setLevel(level)
    formatter = logging.Formatter(
        fmt='%(asctime)s|%(levelname)s|%(message)s',
        datefmt='%Y-%m-%d %H:%M:%S')
    handler = TimedRotatingFileHandler(path,
                                       when="d",
                                       interval=1,
                                       backupCount=0)
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    return

