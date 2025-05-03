#!/bin/bash

BASEDIR="$(dirname $0)"
~/t/FreeCAD_1-revised-on-2025-04-25T20-35-20.0.0-conda-Linux-x86_64-py311.AppImage --console "$(cat $BASEDIR/create_new_file.py)"
nohup ~/t/FreeCAD_1-revised-on-2025-04-25T20-35-20.0.0-conda-Linux-x86_64-py311.AppImage &
