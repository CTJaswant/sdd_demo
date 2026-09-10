#!/bin/bash

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty')

if [[ "$FILE_PATH" == *"appsettings"*.json ]]; then
  if echo "$CONTENT" | grep -qE '"Microsoft.EntityFrameworkCore.Database.Command"\s*:\s*"(Information|Debug|Trace)"'; then
    echo "Blocked: this sets EF Core Command logging to a level that logs full SQL parameter values (PHI)." >&2
    exit 2
  fi
fi

exit 0
 