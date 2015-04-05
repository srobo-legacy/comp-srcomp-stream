#!/usr/bin/env python

from __future__ import print_function

import requests

stream = requests.get('http://localhost:5001', stream=True)

try:
    for l in stream.iter_lines(chunk_size=1):
        print(l)
except KeyboardInterrupt:
    pass
