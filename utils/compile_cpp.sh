#!/bin/bash

if [[ "$1" == "release" || "$1" == "-r" || "$1" == "--release" ]]; then
    scons platform=linux target=template_debug
    scons platform=linux target=template_release
    scons platform=windows target=template_release
else
    scons platform=linux target=template_debug
fi
