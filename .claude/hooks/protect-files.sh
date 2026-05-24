#!/bin/bash
# protect-files.sh — blocks Write/Edit on protected files. No jq dependency.

INPUT=$(cat)
echo "$INPUT" >> /tmp/protect-files-debug.log

# Extract tool_input.file_path from the JSON without jq.
# Matches: "file_path"<ws>:<ws>"<value>" — file paths in our hook payloads
# do not contain unescaped double-quotes, so [^"]* is sufficient.
FILE_PATH=$(printf '%s' "$INPUT" \
  | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' \
  | head -1 \
  | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

PROTECTED_PATTERNS=(".env" "package-lock.json" ".git/")

for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    # Escape backslashes and double-quotes for safe JSON emission.
    esc_path=${FILE_PATH//\\/\\\\}
    esc_path=${esc_path//\"/\\\"}
    printf '{"decision":"block","reason":"Blocked: %s matches protected pattern %s"}\n' \
      "$esc_path" "$pattern"
    exit 0
  fi
done
exit 0
