#!/bin/bash

+ escape()
{
  python -c 'import json,sys; print (json.dumps(sys.stdin.read()))'|
  LC_ALL=C sed 's|\\n||g'
}
