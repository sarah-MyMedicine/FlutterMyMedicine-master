# MongoDB Compass Setup Guide - MyMedicine Project

Complete step-by-step instructions to connect MongoDB Compass to your MyMedicine database.

---

## What is MongoDB Compass?

MongoDB Compass is the **official graphical user interface (GUI)** for MongoDB. Think of it as "Excel for databases" - it lets you:
- ✅ View all your user data visually
- ✅ Search and filter users without writing code
- ✅ Export data to CSV/JSON
- ✅ See real-time statistics
- ✅ Create backups with one click

---

## Step 1: Download MongoDB Compass

### Option A: Download from Official Website

1. **Go to:** https://www.mongodb.com/try/download/compass

2. **Select your platform:**
   - Windows (you) → Already selected
   - Download the `.exe` file (approximately 150 MB)

3. **Click "Download"** (no account required)

### Option B: Direct Download Link

**For Windows:**
```
https://downloads.mongodb.com/compass/mongodb-compass-1.42.2-win32-x64.exe
```

---

## Step 2: Install MongoDB Compass

1. **Run the installer** (`mongodb-compass-xxx-win32-x64.exe`)

2. **Installation wizard:**
   - Click "Next"
   - Accept license agreement
   - Choose installation location (default is fine)
   - Click "Install"
   - Wait 2-3 minutes

3. **Launch MongoDB Compass** (should open automatically)

---

## Step 3: Connect to Your Local Database

### Connection Method 1: Using Connection String (Easiest)

1. **Open MongoDB Compass**

2. **You'll see "New Connection" screen**

3. **In the connection string box, paste:**
   ```
   mongodb://localhost:27017
   ```

4. **Click "Connect"**

5. **Done!** You should see your database immediately.

---

### Connection Method 2: Manual Configuration

If connection string doesn't work, use manual setup:

1. **Click "Fill in connection fields individually"**

2. **Enter these details:**
   ```
   Hostname:     localhost
   Port:         27017
   Authentication: None (leave unchecked)
   ```

3. **Click "Connect"**

---

## Step 4: Navigate to Your MyMedicine Database

### After Connecting:

1. **Left sidebar** shows all databases
   
2. **Look for:** `mymedicine` database
   - If you don't see it, users haven't registered yet
   - Register a test user in your Flutter app first

3. **Click on `mymedicine`** to expand it

4. **You'll see 2 collections:**
   - 📁 `users` - All user accounts
   - 📁 `linkinvitations` - Invitation codes

---

## Step 5: View User Data

### Viewing All Users:

1. **Click on `users` collection**

2. **You'll see a list view of all users**

3. **Each document shows:**
   ```json
   {
     "_id": "65f1234567890abcdef",
     "username": "ahmed123",
     "password": "$2a$10$N9qo8uLOickgx2ZMRZoMye...",  ← Hashed (secure)
     "name": "Ahmed Ali",
     "userType": "patient",
     "caregiverId": null,
     "patientIds": [],
     "fcmToken": null,
     "createdAt": "2026-03-07T10:30:15.123Z",
     "updatedAt": "2026-03-07T10:30:15.123Z"
   }
   ```

4. **Switch between views:**
   - **List View** (default) - Row by row
   - **JSON View** - Raw JSON format
   - **Table View** - Spreadsheet style

---

## Step 6: Search and Filter Users

### Example Queries:

#### Find All Patients:
```json
{ "userType": "patient" }
```

**How to use:**
1. Click **"Filter"** button at top
2. Paste query in the box
3. Press **Enter**
4. See filtered results

---

#### Find All Caregivers:
```json
{ "userType": "caregiver" }
```

---

#### Find Patients Without Caregiver:
```json
{ 
  "userType": "patient", 
  "caregiverId": null 
}
```

---

#### Find Specific User by Username:
```json
{ "username": "ahmed123" }
```

---

#### Find Users Created Today:
```json
{
  "createdAt": {
    "$gte": ISODate("2026-03-07T00:00:00.000Z")
  }
}
```

---

#### Find Patients WITH Caregiver:
```json
{
  "userType": "patient",
  "caregiverId": { "$ne": null }
}
```

---

## Step 7: View Statistics

### Collection Statistics:

1. **Click "Indexes" tab** at top

2. **See:**
   - Total documents (users)
   - Average document size
   - Total collection size
   - Indexes (for query performance)

---

### Aggregation Pipeline (Advanced):

**Count users by type:**

1. Click **"Aggregations"** tab

2. **Add stage:** `$group`

3. **Paste this:**
   ```json
   {
     "_id": "$userType",
     "count": { "$sum": 1 }
   }
   ```

4. **Click "Run"**

5. **See output:**
   ```json
   { "_id": "patient", "count": 32 }
   { "_id": "caregiver", "count": 13 }
   ```

---

## Step 8: Export Data

### Export to CSV:

1. **Filter data** (if needed)

2. **Click "Export Data"** button (top right)

3. **Choose format:**
   - CSV (for Excel)
   - JSON (for backup)

4. **Choose fields to export:**
   - username ✓
   - name ✓
   - userType ✓
   - createdAt ✓
   - password ✗ (uncheck - it's hashed anyway)

5. **Click "Export"**

6. **Save file** (e.g., `users-export-2026-03-07.csv`)

7. **Open in Excel** or Google Sheets

---

## Step 9: View Linked Relationships

### See Patient's Caregiver:

1. **Click on a patient document**

2. **Look for `caregiverId` field**

3. **If it shows ObjectId:**
   ```json
   "caregiverId": ObjectId("65f9876543210fedcba")
   ```

4. **Copy the ID: `65f9876543210fedcba`**

5. **Search in users collection:**
   ```json
   { "_id": ObjectId("65f9876543210fedcba") }
   ```

6. **See the caregiver details**

---

### See Caregiver's Patients:

1. **Click on a caregiver document**

2. **Look at `patientIds` array:**
   ```json
   "patientIds": [
     ObjectId("65f111..."),
     ObjectId("65f222..."),
     ObjectId("65f333...")
   ]
   ```

3. **This caregiver manages 3 patients**

4. **To see patient details, search:**
   ```json
   { "_id": { "$in": [
     ObjectId("65f111..."),
     ObjectId("65f222..."),
     ObjectId("65f333...")
   ]}}
   ```

---

## Step 10: View Invitation Codes

1. **Click `linkinvitations` collection**

2. **You'll see all invitation codes:**
   ```json
   {
     "_id": "65f5555...",
     "invitationCode": "ABC123",
     "patientId": ObjectId("65f1234..."),
     "patientUsername": "ahmed123",
     "patientName": "Ahmed Ali",
     "status": "pending",
     "createdAt": "2026-03-07T10:45:00.000Z",
     "expiresAt": "2026-03-08T10:45:00.000Z"
   }
   ```

3. **Filter by status:**
   - Pending: `{ "status": "pending" }`
   - Accepted: `{ "status": "accepted" }`
   - Expired: `{ "status": "expired" }`

---

## Visual Guide to Interface

### Main Screen Layout:

```
┌─────────────────────────────────────────────────────────┐
│  MongoDB Compass                                   [x]   │
├──────────────┬──────────────────────────────────────────┤
│              │  Database: mymedicine                    │
│ DATABASES    │  ┌─────────────────────────────────────┐│
│              │  │ Filter: { "userType": "patient" }   ││
│ > admin      │  └─────────────────────────────────────┘│
│ v mymedicine │  ────────────────────────────────────────│
│   > users    │  Documents  Schema  Indexes  Explain ... │
│   > linkInv..│  ────────────────────────────────────────│
│              │  [List View] [JSON View] [Table View]    │
│              │  ────────────────────────────────────────│
│              │  📄 username: "ahmed123"                 │
│              │     name: "Ahmed Ali"                    │
│              │     userType: "patient"                  │
│              │     createdAt: 2026-03-07...             │
│              │  ────────────────────────────────────────│
│              │  📄 username: "sara456"                  │
│              │     name: "Sara Caregiver"               │
│              │     userType: "caregiver"                │
│              │  ────────────────────────────────────────│
└──────────────┴──────────────────────────────────────────┘
```

---

## Common Tasks Reference

### Task: Find Unlinked Patients
**Filter:**
```json
{ "userType": "patient", "caregiverId": null }
```

**Export to CSV** → Send to caregivers team

---

### Task: Check Today's Registrations
**Filter:**
```json
{
  "createdAt": {
    "$gte": ISODate("2026-03-07T00:00:00.000Z"),
    "$lt": ISODate("2026-03-08T00:00:00.000Z")
  }
}
```

---

### Task: Find Active Invitations
**Collection:** `linkinvitations`

**Filter:**
```json
{
  "status": "pending",
  "expiresAt": { "$gt": "$$NOW" }
}
```

---

### Task: Count Total Users
**Top of screen shows:** `Documents: 45`

Or run aggregation:
```json
[
  { "$count": "totalUsers" }
]
```

---

### Task: Search by Name (Partial Match)
**Filter:**
```json
{ "name": { "$regex": "Ahmed", "$options": "i" } }
```

**Finds:** "Ahmed Ali", "Mohammed Ahmed", etc.

---

## Troubleshooting

### Issue: "Cannot connect to MongoDB"

**Solution 1:** Check if MongoDB is running
```powershell
Get-Service MongoDB
```
Should show: `Status: Running`

**Solution 2:** Start MongoDB service
```powershell
net start MongoDB
```

---

### Issue: "Database `mymedicine` not showing"

**Cause:** No users registered yet (MongoDB creates database on first insert)

**Solution:** Register a test user in your Flutter app first

---

### Issue: "Connection timed out"

**Check:**
1. MongoDB service is running
2. Port 27017 is not blocked by firewall
3. Connection string is correct: `mongodb://localhost:27017`

---

### Issue: "Authentication failed"

**Cause:** Your local MongoDB doesn't require authentication (default)

**Solution:** Remove authentication in connection settings
- Username: (leave empty)
- Password: (leave empty)
- Authentication: None

---

### Issue: Password field shows weird characters

**This is normal!** Passwords are hashed with bcrypt:
```
$2a$10$N9qo8uLOickgx2ZMRZoMye.IjcKZbePTe/XH1hPNd4HXz0qP
```

You cannot (and should not) see plain passwords. This is correct security.

---

## Advanced Features

### 1. Schema Analysis

**See data types and structure:**

1. Click **"Schema"** tab
2. Compass analyzes your data structure
3. Shows:
   - Field names
   - Data types (String, Date, ObjectId, etc.)
   - Frequency of each field
   - Sample values

---

### 2. Query History

**Reuse previous queries:**

1. Click **"History"** icon (clock icon)
2. See all your recent filters
3. Click to reuse

---

### 3. Query Performance

**Check if queries are fast:**

1. Click **"Explain Plan"** tab
2. Enter your query
3. Click "Explain"
4. See execution stats (milliseconds, documents examined)

---

### 4. Create Indexes (Speed Up Searches)

**If searching by username is slow:**

1. Click **"Indexes"** tab
2. Click **"Create Index"**
3. Fields: `{ "username": 1 }`
4. Click "Create"

MongoDB already creates indexes automatically, but you can add more.

---

### 5. Real-Time Updates

**Compass updates automatically** when data changes:
- New user registered? Refresh to see it
- Manual refresh: Press **F5** or click refresh icon

---

## PowerShell + Compass Workflow

**Recommended workflow:**

1. **Use PowerShell** for admin tasks:
   - Get statistics
   - Reset passwords
   - Delete users

2. **Use Compass** for:
   - Visual browsing
   - Searching users
   - Exporting data
   - Understanding relationships

**Example:**
```powershell
# PowerShell: Get stats
$adminKey = "admin-secret-key-change-this-12345"
Invoke-WebRequest -Uri "http://localhost:5000/api/admin/stats" `
  -Headers @{"x-admin-key"=$adminKey} | 
  Select-Object -ExpandProperty Content

# Then switch to Compass to visually browse those users
```

---

## Connection Settings for Different Environments

### Local Development (Current):
```
mongodb://localhost:27017
```

---

### MongoDB Atlas (Cloud - When you deploy):
```
mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/mymedicine?retryWrites=true&w=majority
```

**Get this from:**
1. MongoDB Atlas dashboard
2. Click "Connect"
3. Choose "Connect using MongoDB Compass"
4. Copy connection string

---

### Docker (If using containers):
```
mongodb://localhost:27017
```
Or if container uses different port:
```
mongodb://localhost:27018
```

---

## Quick Reference Card

| Task | Filter Query |
|------|-------------|
| All patients | `{ "userType": "patient" }` |
| All caregivers | `{ "userType": "caregiver" }` |
| Unlinked patients | `{ "userType": "patient", "caregiverId": null }` |
| Linked patients | `{ "userType": "patient", "caregiverId": { "$ne": null } }` |
| Find by username | `{ "username": "ahmed123" }` |
| Find by name | `{ "name": { "$regex": "Ahmed", "$options": "i" } }` |
| Today's users | `{ "createdAt": { "$gte": ISODate("2026-03-07") } }` |
| Active invitations | `{ "status": "pending", "expiresAt": { "$gt": "$$NOW" } }` |

---

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Refresh | `F5` |
| Focus filter | `Ctrl + F` |
| Clear filter | `Esc` |
| Export data | `Ctrl + E` |
| New tab | `Ctrl + T` |
| Close tab | `Ctrl + W` |
| Query history | `Ctrl + H` |

---

## Security Note

**MongoDB Compass connects directly to your database.**

**⚠️ Be careful when:**
- Deleting documents (no undo!)
- Editing user data
- Exporting sensitive information

**✅ Safe operations:**
- Reading/viewing data
- Filtering and searching
- Exporting to CSV
- Viewing statistics

**🔒 Protected:**
- Passwords are hashed (you can't see them)
- Even in Compass, passwords show as: `$2a$10$...`

---

## Next Steps

After connecting Compass:

1. ✅ **Register test users** in your Flutter app
2. ✅ **Refresh Compass** to see them appear
3. ✅ **Try filter queries** from this guide
4. ✅ **Export to CSV** to see in Excel
5. ✅ **Test invitation system** and watch codes appear
6. ✅ **Link patient to caregiver** and see the relationship

---

## Summary: Quick Start

**3 Steps to Connect:**

1. **Download:** https://www.mongodb.com/try/download/compass

2. **Install:** Run `.exe`, click through wizard

3. **Connect:** Paste `mongodb://localhost:27017` and click "Connect"

**Then:**
- Click `mymedicine` database
- Click `users` collection
- See your users!

**Done!** 🎉

---

## Screenshots Guide (What You'll See)

### 1. New Connection Screen:
```
┌──────────────────────────────────────────────┐
│  New Connection                               │
│                                               │
│  Paste connection string:                    │
│  ┌────────────────────────────────────────┐  │
│  │ mongodb://localhost:27017              │  │
│  └────────────────────────────────────────┘  │
│                                               │
│  Or fill in connection fields individually   │
│                                               │
│  [Cancel]                    [Connect]        │
└──────────────────────────────────────────────┘
```

---

### 2. Connected - Database List:
```
┌──────────────────────────────────────────────┐
│  Databases                                    │
│  ┌──────────────────────────────────────┐    │
│  │ 📁 admin                    3 colls  │    │
│  │ 📁 config                   1 colls  │    │
│  │ 📁 local                    1 colls  │    │
│  │ 📁 mymedicine              2 colls  │ ⬅  │
│  └──────────────────────────────────────┘    │
└──────────────────────────────────────────────┘
```

---

### 3. MyMedicine Database - Collections:
```
┌──────────────────────────────────────────────┐
│  mymedicine                                   │
│  ┌──────────────────────────────────────┐    │
│  │ 📄 users                  45 docs    │    │
│  │ 📄 linkinvitations        12 docs    │    │
│  └──────────────────────────────────────┘    │
└──────────────────────────────────────────────┘
```

---

### 4. Users Collection - List View:
```
┌──────────────────────────────────────────────────────┐
│  users (45)           🔍 Filter  Export  More...     │
├──────────────────────────────────────────────────────┤
│  📄 ahmed123                                          │
│     name: "Ahmed Ali"                                │
│     userType: "patient"                              │
│     createdAt: Fri Mar 07 2026 10:30:15 GMT+0000    │
│  ──────────────────────────────────────────────────  │
│  📄 sara456                                          │
│     name: "Sara Caregiver"                           │
│     userType: "caregiver"                            │
│     createdAt: Fri Mar 07 2026 11:15:22 GMT+0000    │
│  ──────────────────────────────────────────────────  │
│  ...                                                 │
└──────────────────────────────────────────────────────┘
```

---

## Support Resources

**MongoDB Compass Documentation:**
https://www.mongodb.com/docs/compass/current/

**MongoDB Query Language:**
https://www.mongodb.com/docs/manual/tutorial/query-documents/

**Video Tutorial:**
https://www.youtube.com/watch?v=5QEbvGP-nwY

**Your Admin API (Alternative to Compass):**
- See: `DATABASE_ACCESS_GUIDE.md`
- Test: `backend/test-admin-api.ps1`

---

## Congratulations! 🎉

You now know how to:
- ✅ Install MongoDB Compass
- ✅ Connect to your database
- ✅ Browse users and data
- ✅ Search and filter
- ✅ Export to CSV
- ✅ View relationships
- ✅ Monitor statistics

**Your database is fully accessible and manageable!**
