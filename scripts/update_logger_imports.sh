#!/bin/bash

# Script to update logger.dart imports to use the new logging.dart barrel export
# Usage: ./scripts/update_logger_imports.sh

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB_DIR="$PROJECT_DIR/gitdoit/lib"
SCRIPTS_DIR="$PROJECT_DIR/gitdoit/scripts"

echo "========================================"
echo "Updating logger imports in GitDoIt"
echo "========================================"
echo ""

# Find all Dart files that import logger.dart
echo "Searching for files with logger.dart imports..."
echo ""

FILES=$(grep -rl "import.*utils/logger\.dart" "$LIB_DIR" "$SCRIPTS_DIR" 2>/dev/null || true)

if [ -z "$FILES" ]; then
    echo "No files found with logger.dart imports."
    exit 0
fi

echo "Found ${FILES} files to update"
echo ""

# Counter for updated files
count=0

for file in $FILES; do
    # Get relative path from project root
    rel_path="${file#$PROJECT_DIR/}"
    
    # Calculate the relative path to utils from the file's directory
    file_dir=$(dirname "$file")
    
    # Count directory depth from lib/
    if [[ "$file_dir" == *"/lib/"* ]]; then
        # Extract path after lib/
        path_after_lib="${file_dir#*/lib/}"
        # Count slashes to determine depth
        depth=$(echo "$path_after_lib" | tr -cd '/' | wc -c)
        
        # Build relative path to utils
        rel_utils="../"
        for ((i=0; i<depth; i++)); do
            rel_utils+="../"
        done
        rel_utils+="utils"
    else
        rel_utils="../utils"
    fi
    
    echo "Updating: $rel_path"
    
    # Replace the import line
    # Handle both single and double quotes
    sed -i '' "s|import '../utils/logger.dart';|import '${rel_utils}/logging.dart';|g" "$file"
    sed -i '' "s|import \"../utils/logger.dart\";|import \"${rel_utils}/logging.dart\";|g" "$file"
    sed -i '' "s|import '../../utils/logger.dart';|import '${rel_utils}/logging.dart';|g" "$file"
    sed -i '' "s|import \"../../utils/logger.dart\";|import \"${rel_utils}/logging.dart\";|g" "$file"
    sed -i '' "s|import '../../../utils/logger.dart';|import '${rel_utils}/logging.dart';|g" "$file"
    sed -i '' "s|import \"../../../utils/logger.dart\";|import \"${rel_utils}/logging.dart\";|g" "$file"
    
    ((count++))
done

echo ""
echo "========================================"
echo "Updated $count files successfully!"
echo "========================================"
echo ""
echo "New import format: import '.../utils/logging.dart';"
echo ""
echo "Run 'flutter analyze' to verify the changes."
