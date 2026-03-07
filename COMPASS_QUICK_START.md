# MongoDB Compass - Quick Start (1-Page Guide)

## 🚀 3 Steps to Connect

### Step 1: Download & Install
```
1. Go to: https://www.mongodb.com/try/download/compass
2. Download Windows version (150MB)
3. Run installer → Click "Next" through wizard
4. Launch MongoDB Compass
```

### Step 2: Connect to Database
```
1. Paste connection string: mongodb://localhost:27017
2. Click "Connect"
3. Done!
```

### Step 3: View Your Data
```
1. Click "mymedicine" database (left sidebar)
2. Click "users" collection
3. See all your users!
```

---

## 📊 What You'll See

### Your Database Structure:
```
mymedicine/
├── users (all accounts)
│   ├── username
│   ├── password (hashed - secure)
│   ├── name
│   ├── userType (patient/caregiver)
│   ├── caregiverId (if linked)
│   └── createdAt
│
└── linkinvitations (invitation codes)
    ├── invitationCode (6-digit)
    ├── patientUsername
    ├── status (pending/accepted/expired)
    └── expiresAt (24 hours)
```

---

## 🔍 Common Filter Queries

Copy & paste into the Filter box:

### All Patients:
```json
{ "userType": "patient" }
```

### All Caregivers:
```json
{ "userType": "caregiver" }
```

### Unlinked Patients:
```json
{ "userType": "patient", "caregiverId": null }
```

### Find Specific User:
```json
{ "username": "ahmed123" }
```

### Today's Registrations:
```json
{ "createdAt": { "$gte": ISODate("2026-03-07") } }
```

### Search by Name:
```json
{ "name": { "$regex": "Ahmed", "$options": "i" } }
```

---

## 📤 Export Data

```
1. Apply filter (if needed)
2. Click "Export Data" button (top right)
3. Choose CSV or JSON
4. Select fields to export
5. Save file
6. Open in Excel
```

---

## 🔧 Troubleshooting

### "Cannot connect"
```powershell
# Check MongoDB is running:
Get-Service MongoDB

# Should show: Status: Running
# If not, start it:
net start MongoDB
```

### "Database not showing"
```
Register a test user in your Flutter app first.
MongoDB creates database on first insert.
```

### "Authentication failed"
```
Leave username/password blank.
Your local MongoDB doesn't require authentication.
```

---

## 📱 Interface Overview

```
┌─────────────────────────────────────────────────────┐
│  MongoDB Compass                              [x]   │
├──────────┬──────────────────────────────────────────┤
│          │  Filter: { "userType": "patient" }        │
│ DATABASE │  ─────────────────────────────────────────│
│          │  📄 ahmed123                              │
│ > admin  │     name: "Ahmed Ali"                     │
│ v mymed..│     userType: "patient"                   │
│   >users │  ─────────────────────────────────────────│
│   >linkI.│  📄 sara456                               │
│          │     name: "Sara Caregiver"                │
│          │     userType: "caregiver"                 │
└──────────┴──────────────────────────────────────────┘
```

---

## ⚡ Quick Reference

| Task | Action |
|------|--------|
| **Refresh data** | Press F5 |
| **Filter** | Click Filter box, paste JSON, Enter |
| **Export** | Top right → Export Data |
| **Search** | Type in Filter box |
| **View JSON** | Click "JSON View" tab |
| **Count** | Shows at top: "Documents: 45" |
| **Clear filter** | Press Esc or click X |

---

## 🎯 Your Connection Details

```
Connection String:  mongodb://localhost:27017
Database Name:      mymedicine
Collections:        users, linkinvitations
Port:              27017 (default)
Host:              localhost
Authentication:    None (local dev)
```

---

## 💡 Pro Tips

1. **Use Table View** for Excel-like interface
2. **Export regularly** as backup
3. **Filter before exporting** to get specific data
4. **History button** saves your recent queries
5. **Schema tab** shows data structure

---

## 🔐 Security

**What you CAN see:**
- ✅ Usernames
- ✅ Full names
- ✅ User types
- ✅ Creation dates
- ✅ Relationships

**What you CANNOT see:**
- ❌ Plain passwords (hashed as `$2a$10$...`)
- This is correct security!

---

## 📚 Full Documentation

For detailed guide, see:
- `MONGODB_COMPASS_SETUP.md` (this project)
- https://www.mongodb.com/docs/compass/

---

## ✅ Checklist

- [ ] Downloaded MongoDB Compass
- [ ] Installed successfully
- [ ] Connected to localhost:27017
- [ ] Saw mymedicine database
- [ ] Viewed users collection
- [ ] Tried filter query
- [ ] Exported to CSV
- [ ] Bookmarked this guide

---

## 🎉 You're Ready!

**Connection works?** → You can now manage your users visually!

**Having issues?** → Check "Troubleshooting" section above

**Need more help?** → See full guide in `MONGODB_COMPASS_SETUP.md`
