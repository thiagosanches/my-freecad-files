#!/bin/bash

FREECAD_FILE="$1"
FREECAD_PREVIOUS_FILE="$FREECAD_FILE.previous.FCStd"
TEMP_CURRENT_FOLDER="temp_current/"
TEMP_PREVIOUS_FOLDER="temp_previous/"

# Get the previous version of the file.
git show HEAD~1:$FREECAD_FILE > $FREECAD_PREVIOUS_FILE

rm -rf "$TEMP_FOLDER"
unzip -qq "$FREECAD_FILE" -d "$TEMP_CURRENT_FOLDER" Document.xml GuiDocument.xml '*.fstd'
unzip -qq "$FREECAD_PREVIOUS_FILE" -d "$TEMP_PREVIOUS_FOLDER" Document.xml GuiDocument.xml '*.fstd'

diff -r \
    --unified \
    --ignore-matching-lines='^<!--' \
    --exclude='*.brp' \
    --exclude='*.bin' \
    --exclude='Thumbnail.png' \
    --color \
    $TEMP_PREVIOUS_FOLDER $TEMP_CURRENT_FOLDER

rm -rf "$TEMP_PREVIOUS_FOLDER" "$TEMP_CURRENT_FOLDER"