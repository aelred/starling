import os
import appdirs

path = os.path.realpath(
    os.path.join(os.getcwd(), os.path.dirname(__file__), '..', 'modules'))

cache_dir = appdirs.user_cache_dir('starling')
try:
    os.mkdir(cache_dir)
except OSError, e:
    # cache dir exists
    pass
