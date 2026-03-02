# Offline Mode Test Plan

## Test Scenario A: Pure Offline Mode

### Setup
1. Turn off WiFi and mobile data
2. Launch app
3. Select "Continue Offline"
4. Select vault folder

### Tests
- [ ] Can create new issue
- [ ] Issue saved to vault folder as markdown
- [ ] Issue appears in "Vault" repo
- [ ] Can edit issue title
- [ ] Can edit issue body
- [ ] Can close/reopen issue
- [ ] Changes saved locally
- [ ] No errors shown

### Expected
- All CRUD operations work
- Issues saved as .md files
- SnackBar shows "queued for sync"

---

## Test Scenario B: Offline with Cached Repos

### Setup
1. Login with GitHub token
2. Load repositories
3. Turn off network
4. Navigate to repo

### Tests
- [ ] Can view cached repos
- [ ] Can view cached issues
- [ ] Can create new issue
- [ ] Can edit existing issue
- [ ] Can close issue
- [ ] Can reopen issue
- [ ] Changes queued
- [ ] Pending count shown

### Expected
- Cached data visible
- All operations queued
- Badge shows pending count

---

## Test Scenario C: Network Returns

### Setup
1. Create issues offline
2. Edit issues offline
3. Close issues offline
4. Turn on network
5. Pull to refresh

### Tests
- [ ] Network detected automatically
- [ ] Sync starts automatically
- [ ] Pending operations processed
- [ ] Issues created on GitHub
- [ ] Issues updated on GitHub
- [ ] Issues closed on GitHub
- [ ] Pending count goes to 0
- [ ] Success notifications shown

### Expected
- Auto-sync within 2 seconds
- All operations synced
- Badge disappears
- Success messages shown

---

## Test Scenario D: Sync Conflicts

### Setup
1. Create issue offline
2. Edit same issue on GitHub web
3. Sync

### Tests
- [ ] Conflict detected
- [ ] User notified
- [ ] Resolution options shown
- [ ] No data lost

### Expected
- Graceful conflict handling
- User can choose version

---

## Success Criteria

All scenarios must pass:
- No crashes
- No data loss
- Clear user feedback
- Automatic sync on network return
- Pending operations persist across app restarts
