#!/bin/bash


scons platform=linux target=template_debug
scons platform=linux target=template_release

scons platform=windows target=template_debug
scons platform=windows target=template_release
