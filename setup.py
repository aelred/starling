# use setuptools if available, else use distutils
try:
    from setuptools import setup
except ImportError:
    from distutils.core import setup

import os

def is_star(f):
    return os.path.splitext(f)[1] == '.star'

mods_dir = 'modules'
modules = [f for f in next(os.walk(mods_dir))[2] if is_star(f)]
print [(mods_dir, os.path.join(mods_dir, f)) for f in modules]

setup (
    name='starling',
    version='0.1',
    description='Pure, lazy functional language',
    author='Felix Chapman',
    packages=['starling'],
    setup_requires = ['enum34'],
    install_requires=['pyparsing', 'appdirs', 'enum34', 'llvmlite'],
    entry_points={
        'console_scripts': ['starling = starling.__main__:main']
    },
    data_files=[(mods_dir, [os.path.join(mods_dir, f) for f in modules])]
)
