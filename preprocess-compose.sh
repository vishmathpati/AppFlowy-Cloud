#!/bin/bash

# Path to your Docker Compose file (assuming it's in the same directory as this script)
COMPOSE_FILE="./docker-compose.yml"

# Temporary file
TEMP_FILE=$(mktemp)

echo "Starting preprocessing of $COMPOSE_FILE"

# Process the file
awk '
BEGIN { in_appflowy_cloud = 0; in_environment = 0; env_var_count = 0; }
/^  appflowy_cloud:/ { in_appflowy_cloud = 1; print; next }
/^  [a-zA-Z_]+:/ { in_appflowy_cloud = 0; in_environment = 0 }
in_appflowy_cloud && /^    environment:/ { in_environment = 1; print "    environment:"; next }
in_environment && /^      -/ { 
    split($0, a, " ")
    key = a[2]
    sub(/=.*/, "", key)
    value = substr($0, index($0, "=") + 1)
    gsub(/^[ \t]+|[ \t]+$/, "", value)  # Trim leading/trailing whitespace
    printf "      %s: %s\n", key, value
    env_var_count++
    next
}
{ print }
END { print "Processed " env_var_count " environment variables for appflowy_cloud service." > "/dev/stderr" }
' "$COMPOSE_FILE" > "$TEMP_FILE"

# Check if any changes were made
if cmp -s "$COMPOSE_FILE" "$TEMP_FILE"; then
    echo "No changes were necessary in $COMPOSE_FILE"
    rm "$TEMP_FILE"
else
    # Replace the original file with the processed one
    mv "$TEMP_FILE" "$COMPOSE_FILE"
    echo "Successfully preprocessed $COMPOSE_FILE"
fi

echo "Preprocessing complete"
