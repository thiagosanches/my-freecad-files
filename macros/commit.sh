#!/bin/bash

FREECAD_FILE="$1"
FREECAD_PREVIOUS_FILE="$FREECAD_FILE.previous.FCStd"
TEMP_CURRENT_FOLDER="temp_current/"
TEMP_PREVIOUS_FOLDER="temp_previous/"

# Get the previous version of the file.
git show HEAD~1:$FREECAD_FILE > $FREECAD_PREVIOUS_FILE

rm -rf "$TEMP_FOLDER"
unzip -qq "$FREECAD_FILE" -d "$TEMP_CURRENT_FOLDER" Document.xml GuiDocument.xml
unzip -qq "$FREECAD_PREVIOUS_FILE" -d "$TEMP_PREVIOUS_FOLDER" Document.xml GuiDocument.xml

MAIN_DIFF=$(diff -r \
    --unified \
    --ignore-matching-lines='^<!--' \
    --exclude='*.brp' \
    --exclude='*.bin' \
    --exclude='Thumbnail.png' \
    --color \
    $TEMP_PREVIOUS_FOLDER $TEMP_CURRENT_FOLDER)

CURRENT_FILE_CONTENT=$(cat $TEMP_CURRENT_FOLDER/Document.xml)
CURRENT_FILE_CONTENT=$(echo -e "$CURRENT_FILE_CONTENT" | sed -z 's/\n//g' | jq -Rs)
MAIN_DIFF=$(echo -e "$MAIN_DIFF" | sed -z 's/\n//g' | jq -Rs)

PROMPT="As an experienced FreeCAD user with in-depth knowledge of its core functionality, your main task is to craft a concise and descriptive commit message that clearly explains the changes made to the CAD model, using simple language and referencing the provided file name. This will enable effective change tracking through accurate and informative messages. Please disregard any differences related to camera settings and concentrate on changes affecting solids and sketches. CURRENT FILE NAME: $FREECAD_FILE CURRENT FILE CONTENT: $CURRENT_FILE_CONTENT DIFF: $MAIN_DIFF"

PROMPT=$(echo "$PROMPT" | sed 's/["\]//g')

cat <<EOF > body.json
{
    "model": "gpt-4.1",
    "messages": [
        {
            "role": "user",
            "content": "$PROMPT"
        }
    ]
}
EOF





MESSAGE=$(time curl "https://api.openai.com/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d @body.json | jq '.choices[].message.content')

rm -rf "$TEMP_PREVIOUS_FOLDER" "$TEMP_CURRENT_FOLDER" "$FREECAD_PREVIOUS_FILE" body.json
echo "$MESSAGE"
