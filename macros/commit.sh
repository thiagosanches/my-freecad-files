#!/bin/bash

COMMIT_FILE="$0"
FREECAD_FILE="$1"
FREECAD_PREVIOUS_FILE="$FREECAD_FILE.previous.FCStd"
TEMP_CURRENT_FOLDER="temp_current/"
TEMP_PREVIOUS_FOLDER="temp_previous/"
FREECAD_FILE_ONLY="$(basename "$FREECAD_FILE")"

# Assuming you have all your FreeCAD files stored under a root folder that is a Git repository.
cd $(dirname "$FREECAD_FILE")
MACROS_FOLDER="$(dirname $COMMIT_FILE)"

# You just need to define the file with the following content:
# OPENAI_API_KEY="sk-YOUR-KEY-GOES-HERE"
source "$MACROS_FOLDER/ai.properties"

mkdir "$TEMP_CURRENT_FOLDER"
mkdir "$TEMP_PREVIOUS_FOLDER"

# Get the previous version of the file.
git show HEAD~1:$FREECAD_FILE_ONLY > $FREECAD_PREVIOUS_FILE

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

PROMPT="As an experienced FreeCAD user with in-depth knowledge of its core functionality, your main task is to craft a concise and descriptive git commit message that clearly explains the changes made to the CAD model, using simple language and referencing the provided file name. This will enable effective change tracking through accurate and informative messages. Also, please disregard any differences related to camera settings and concentrate on changes affecting solids and sketches. CURRENT FILE NAME: $FREECAD_FILE_ONLY CURRENT FILE CONTENT: $CURRENT_FILE_CONTENT DIFF: $MAIN_DIFF"

PROMPT=$(echo "$PROMPT" | sed 's/["\]//g')

# If you want to use OLLAMA with the DeepSeek model locally, the model is: deepseek-r1:8b
cat <<EOF > body.json
{
    "model": "o4-mini",
    "messages": [
        {
            "role": "user",
            "content": "$PROMPT"
        }
    ]
}
EOF

# You can switch to OLLAMA locally and use any model that suits your needs. For example:
#curl -X POST http://localhost:8080/api/chat/completions \
#-H "Authorization: Bearer YOUR_OLLAMA_TOKEN_GOES_HERE" \
#-H "Content-Type: application/json" \
#-d @body.json | jq #'.choices[].message.content' --raw-output)

MESSAGE=$(curl "https://api.openai.com/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d @body.json | jq '.choices[].message.content' --raw-output)

rm -rf "$TEMP_PREVIOUS_FOLDER" "$TEMP_CURRENT_FOLDER" "$FREECAD_PREVIOUS_FILE" body.json
echo "$MESSAGE"

git pull
git add "$FREECAD_FILE"
git commit -m "$MESSAGE"
git push origin main
