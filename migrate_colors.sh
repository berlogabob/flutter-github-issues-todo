#!/bin/bash

# Color Migration Script
# Updates all Dart files to use new simplified color names

echo "🎨 Migrating colors to simplified palette..."

# Find all Dart files in lib/
FILES=$(find lib -name "*.dart" -type f)

for file in $FILES; do
  # Create backup comment at top if it's the first change
  if grep -q "AppColors\.orangePrimary" "$file" || \
     grep -q "AppColors\.cardBackground" || \
     grep -q "AppColors\.secondaryText" || \
     grep -q "AppColors\.borderColor" || \
     grep -q "AppColors\.white" || \
     grep -q "AppColors\.red" || \
     grep -q "AppColors\.blue"; then
    
    echo "  → $file"
    
    # Replace color names (order matters - do specific ones first)
    sed -i '' 's/AppColors\.orangePrimary/AppColors.primary/g' "$file"
    sed -i '' 's/AppColors\.cardBackground/AppColors.card/g' "$file"
    sed -i '' 's/AppColors\.secondaryText/AppColors.textSecondary/g' "$file"
    sed -i '' 's/AppColors\.borderColor/AppColors.border/g' "$file"
    sed -i '' 's/AppColors\.white/AppColors.text/g' "$file"
    sed -i '' 's/AppColors\.red/AppColors.error/g' "$file"
    sed -i '' 's/AppColors\.blue/AppColors.link/g' "$file"
    sed -i '' 's/AppColors\.surfaceColor/AppColors.dark/g' "$file"
    sed -i '' 's/AppColors\.darkBackground/AppColors.dark/g' "$file"
    sed -i '' 's/AppColors\.issueOpen/AppColors.success/g' "$file"
    sed -i '' 's/AppColors\.issueClosed/AppColors.muted/g' "$file"
    sed -i '' 's/AppColors\.orangeSecondary/AppColors.primary/g' "$file"
    sed -i '' 's/AppColors\.orangeLight/AppColors.primary/g' "$file"
  fi
done

echo "✅ Migration complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Run: flutter analyze"
echo "  2. Run: flutter test"
echo "  3. Run: dart format ."
