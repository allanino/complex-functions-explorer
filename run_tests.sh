#!/bin/bash
# Download godot to run tests headless
wget https://github.com/godotengine/godot/releases/download/4.2.1-stable/Godot_v4.2.1-stable_linux.x86_64.zip
unzip Godot_v4.2.1-stable_linux.x86_64.zip
./Godot_v4.2.1-stable_linux.x86_64 --headless -s addons/gut/gut_cmdln.gd -d -gdir=res://tests
