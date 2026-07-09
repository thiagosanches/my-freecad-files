#!/bin/bash

set -euo pipefail

[[ $# -lt 1 ]] && { echo "Usage: $0 <freecad-file>" >&2; exit 1; }

COMMIT_FILE="$(realpath "$0")"
FREECAD_FILE="$(realpath "$1")"
FREECAD_PREVIOUS_FILE="$FREECAD_FILE.previous.FCStd"
TEMP_CURRENT_FOLDER="temp_current/"
TEMP_PREVIOUS_FOLDER="temp_previous/"
FREECAD_FILE_ONLY="$(basename "$FREECAD_FILE")"

# Assuming you have all your FreeCAD files stored under a root folder that is a Git repository.
cd "$(dirname "$FREECAD_FILE")"
MACROS_FOLDER="$(dirname "$COMMIT_FILE")"

BODY_JSON="$(mktemp --suffix=.json)"

# Cleanup temp files on exit (success or failure)
trap 'rm -rf "$TEMP_PREVIOUS_FOLDER" "$TEMP_CURRENT_FOLDER" "$FREECAD_PREVIOUS_FILE" "$BODY_JSON"' EXIT

# Pull before making changes to avoid mid-script conflicts
git pull

# You just need to define the file with the following content:
source ~/.openrouter.ai.properties

mkdir -p "$TEMP_CURRENT_FOLDER"
mkdir -p "$TEMP_PREVIOUS_FOLDER"

unzip -qq "$FREECAD_FILE" -d "$TEMP_CURRENT_FOLDER" Document.xml GuiDocument.xml
CURRENT_FILE_CONTENT=$(cat "$TEMP_CURRENT_FOLDER/Document.xml")

# Check if a previous committed version exists (not a brand new file).
IS_NEW_FILE=false
if ! git show HEAD:"$FREECAD_FILE_ONLY" > "$FREECAD_PREVIOUS_FILE" 2>/dev/null; then
    IS_NEW_FILE=true
    echo "No previous commit found for '$FREECAD_FILE_ONLY' — treating as new file." >&2
fi

if [[ "$IS_NEW_FILE" == false ]]; then
    unzip -qq "$FREECAD_PREVIOUS_FILE" -d "$TEMP_PREVIOUS_FOLDER" Document.xml GuiDocument.xml

    # diff exits 1 when differences are found; || true prevents set -e from aborting
    MAIN_DIFF=$(diff -r \
        --unified \
        --ignore-matching-lines='^<!--' \
        --exclude='*.brp' \
        --exclude='*.bin' \
        --exclude='Thumbnail.png' \
        "$TEMP_PREVIOUS_FOLDER" "$TEMP_CURRENT_FOLDER") || true

    PROMPT="As an experienced FreeCAD user with in-depth knowledge of its core functionality, your main task is to craft a concise and descriptive git commit message that clearly explains the changes made to the CAD model, using simple language and referencing the provided file name. This will enable effective change tracking through accurate and informative messages. Also, please disregard any differences related to camera settings and concentrate on changes affecting solids and sketches. CURRENT FILE NAME: $FREECAD_FILE_ONLY CURRENT FILE CONTENT: $CURRENT_FILE_CONTENT DIFF: $MAIN_DIFF"
else
    PROMPT="As an experienced FreeCAD user with in-depth knowledge of its core functionality, your main task is to craft a concise and descriptive git commit message for a brand new FreeCAD file being added to the repository for the first time. Use simple language and reference the provided file name. CURRENT FILE NAME: $FREECAD_FILE_ONLY CURRENT FILE CONTENT: $CURRENT_FILE_CONTENT"
fi

# Build JSON body safely via jq — pipe prompt via stdin to avoid ARG_MAX limits
# If you want to use OLLAMA with the DeepSeek model locally, the model is: deepseek-r1:8b
printf '%s' "$PROMPT" | jq -Rs \
    --arg model "deepseek/deepseek-v4-flash" \
    '{model: $model, messages: [{role: "user", content: .}]}' > "$BODY_JSON"

# You can switch to OLLAMA locally and use any model that suits your needs. For example:
#curl -X POST http://localhost:8080/api/chat/completions \
#-H "Authorization: Bearer YOUR_OLLAMA_TOKEN_GOES_HERE" \
#-H "Content-Type: application/json" \
#-d @body.json | jq '.choices[].message.content' --raw-output

MESSAGE=$(curl "https://openrouter.ai/api/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OR_KEY_GIT_COMMIT_MESSAGE" \
    -d @"$BODY_JSON" | jq '.choices[].message.content' --raw-output)

[[ -z "$MESSAGE" ]] && { echo "Failed to generate commit message from API." >&2; exit 1; }

echo "$MESSAGE"

git add "$FREECAD_FILE"
echo "$MESSAGE" | git commit -F -
git push origin main
