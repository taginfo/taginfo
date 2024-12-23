#!/usr/bin/python3
#
#  Needs ruamel Python library (Debian: python3-ruamel.yaml)
#

import os
from ruamel.yaml import YAML

yaml = YAML()
yaml.indent(mapping=4, sequence=4, offset=4)
yaml.width = 1000

dir = 'web/i18n'
directory = os.fsencode(dir)

for file in os.listdir(directory):
    if not os.path.islink(file):
        filename = os.fsdecode(file)
        if filename.endswith(".yml"):
            fn = os.path.join(directory, file)
            with open(fn, 'r', encoding="utf-8") as f:
                data = yaml.load(f)

            # Put transformations here

            #if 'database_statistics' in data['reports']:
            #    if 'db' not in data['pages']['sources']:
            #        data['pages']['sources']['db'] = {}
            #    data['pages']['sources']['db']['stats'] = data['reports']['database_statistics']
            #    del data['reports']['database_statistics']

            with open(fn, 'w', encoding="utf-8") as f:
                yaml.dump(data, f)

