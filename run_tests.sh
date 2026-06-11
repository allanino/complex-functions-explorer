#!/bin/bash
set -o pipefail

godot \
--headless \
-s addons/gut/gut_cmdln.gd \
-gdir=res://tests \
-ginclude_subdirs \
-glog=1 \
-gexit \
2>&1 | tee gut.log


grep -i -E "SCRIPT ERROR|FAILED|ERROR|NOT OK|WARNING|ORPHANED|CRASHED|INVALID" gut.log && exit 1