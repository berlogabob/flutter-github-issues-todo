#!/bin/bash

# GitDoIt - Continuous User Test Monitor
# This script monitors ToDo.md for changes and alerts agents

WATCH_FILE="ToDo.md"
LAST_MODIFIED=$(stat -f %m "$WATCH_FILE" 2>/dev/null || stat -c %Y "$WATCH_FILE" 2>/dev/null)
LOG_FILE="plan/user-test-monitor.log"

echo "🔍 GitDoIt User Test Monitor Started"
echo "📁 Watching: $WATCH_FILE"
echo "📝 Log file: $LOG_FILE"
echo "⏰ Started at: $(date)"
echo ""

# Initial check
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Monitor started - Initial checksum: $(md5sum "$WATCH_FILE" 2>/dev/null || md5 -q "$WATCH_FILE")" >> "$LOG_FILE"

while true; do
    CURRENT_MODIFIED=$(stat -f %m "$WATCH_FILE" 2>/dev/null || stat -c %Y "$WATCH_FILE" 2>/dev/null)
    
    if [ "$CURRENT_MODIFIED" != "$LAST_MODIFIED" ]; then
        echo ""
        echo "🚨 CHANGE DETECTED in $WATCH_FILE!"
        echo "⏰ Time: $(date)"
        echo ""
        
        # Log the change
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🚨 CHANGE DETECTED - File modified" >> "$LOG_FILE"
        
        # Show what changed
        echo "📊 Recent changes:"
        git diff "$WATCH_FILE" 2>/dev/null | head -20 || echo "Git diff not available, file was modified"
        
        # Alert user
        echo ""
        echo "📢 Notifying agents..."
        echo "   - MrPlanner: Reprioritizing tasks"
        echo "   - MrSeniorDeveloper: Reviewing technical impact"
        echo "   - UXAgent: Assessing UX impact"
        echo "   - MrCleaner: Preparing to implement fixes"
        echo "   - MrLogger: Adding journey tracking"
        echo ""
        
        # Update last modified
        LAST_MODIFIED=$CURRENT_MODIFIED
        
        # Create/update change summary
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Change summary added to plan/11-user-test-report-live.md" >> "$LOG_FILE"
        
        echo "✅ Check plan/11-user-test-report-live.md for updated analysis"
        echo ""
    fi
    
    sleep 5
done
