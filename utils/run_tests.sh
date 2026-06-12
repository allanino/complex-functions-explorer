#!/bin/bash
set +e

godot \
--headless \
-s addons/gut/gut_cmdln.gd \
-gdir=res://tests \
-ginclude_subdirs \
-glog=1 \
-gexit \
2>&1 | tee gut.log


if grep -i -E "SCRIPT ERROR|FAILED:|NOT OK|ORPHANED|CRASHED|INVALID" gut.log; then
    echo "::error::GUT tests failed"
    exit 1
fi

exit 0