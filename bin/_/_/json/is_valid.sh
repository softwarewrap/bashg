#!/bin/bash

:json:is_valid()
{
   python -c "import sys,json;json.loads(sys.stdin.read())" &>/dev/null
}
