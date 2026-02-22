#!/usr/bin/env bash

# GitDoIt Screen Generator Script
# 
# Usage: 
#   ./generate_screen.sh <screen_name>
# 
# Example:
#   ./generate_screen.sh splash
#   ./generate_screen.sh user_profile
#
# This will create:
#   - lib/screens/<screen_name>_screen.dart
#   - test/screens/<screen_name>_screen_test.dart

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if screen name is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Screen name is required${NC}"
    echo "Usage: ./generate_screen.sh <screen_name>"
    echo "Example: ./generate_screen.sh splash"
    exit 1
fi

# Convert to snake_case
SCREEN_NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
SCREEN_NAME_PASCAL=$(echo "$SCREEN_NAME" | sed -r 's/(^|_)([a-z])/\U\2/g')
SCREEN_NAME_CAMEL=$(echo "$SCREEN_NAME" | sed -r 's/(_[a-z])/\U\1/g' | sed -r 's/^([a-z])/\L\1/')
SCREEN_NAME_UPPER=$(echo "$SCREEN_NAME" | tr '[:lower:]' '[:upper:]' | tr '_' ' ')

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Template file
TEMPLATE_FILE="$SCRIPT_DIR/templates/screen_template.dart"

# Check if template exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo -e "${RED}Error: Template file not found at $TEMPLATE_FILE${NC}"
    exit 1
fi

# Output file
OUTPUT_FILE="$PROJECT_ROOT/lib/screens/${SCREEN_NAME}_screen.dart"
TEST_OUTPUT_FILE="$PROJECT_ROOT/test/screens/${SCREEN_NAME}_screen_test.dart"

# Check if file already exists
if [ -f "$OUTPUT_FILE" ]; then
    echo -e "${YELLOW}Warning: $OUTPUT_FILE already exists${NC}"
    read -p "Overwrite? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create directories if they don't exist
mkdir -p "$(dirname "$OUTPUT_FILE")"
mkdir -p "$(dirname "$TEST_OUTPUT_FILE")"

# Generate screen file from template
echo -e "${GREEN}Generating screen: $OUTPUT_FILE${NC}"

sed -e "s/\[SCREEN_NAME_PASCAL\]/$SCREEN_NAME_PASCAL/g" \
    -e "s/\[SCREEN_NAME_CAMEL\]/$SCREEN_NAME_CAMEL/g" \
    -e "s/\[SCREEN_NAME_UPPER\]/$SCREEN_NAME_UPPER/g" \
    -e "s/\[SCREEN_DESCRIPTION\]/$SCREEN_NAME_PASCAL Screen/g" \
    "$TEMPLATE_FILE" > "$OUTPUT_FILE"

# Generate test file from template
echo -e "${GREEN}Generating test: $TEST_OUTPUT_FILE${NC}"

cat > "$TEST_OUTPUT_FILE" << EOF
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gitdoit/providers/auth_provider.dart';
import 'package:gitdoit/providers/issues_provider.dart';
import 'package:gitdoit/screens/${SCREEN_NAME}_screen.dart';

void main() {
  group('${SCREEN_NAME_PASCAL}Screen', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => IssuesProvider()),
          ],
          child: const MaterialApp(
            home: const ${SCREEN_NAME_PASCAL}Screen(),
          ),
        ),
      );

      // TODO: Add specific assertions for this screen
      expect(find.byType(${SCREEN_NAME_PASCAL}Screen), findsOneWidget);
    });
  });
}
EOF

echo -e "${GREEN}✅ Screen generation complete!${NC}"
echo ""
echo "Created files:"
echo "  - $OUTPUT_FILE"
echo "  - $TEST_OUTPUT_FILE"
echo ""
echo "Next steps:"
echo "  1. Add the screen to your routes in main.dart"
echo "  2. Implement the screen content"
echo "  3. Write specific tests"
