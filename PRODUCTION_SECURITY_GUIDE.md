# Database Security & Production Setup Guide

## Current Status: ✅ Secure Foundation (bcrypt + JWT)

Your backend already implements industry-standard security:
- ✅ Password hashing with bcrypt (10 rounds)
- ✅ JWT token authentication
- ✅ MongoDB with schema validation
- ✅ Input validation on registration/login

---

## Production Security Checklist

### 1. Environment Variables (.env) - CRITICAL ⚠️

**Current Risk:** Default JWT secret in code  
**Fix:** Use strong secret in production

```bash
# backend/.env (NEVER commit this file!)
NODE_ENV=production
PORT=5000

# MongoDB Connection (use MongoDB Atlas for production)
MONGO_URI=mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/mymedicine?retryWrites=true&w=majority

# JWT Secret - Generate a strong random string
# Use: node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
JWT_SECRET=your-generated-super-long-random-string-here-64-characters-minimum

# Optional: Firebase Cloud Messaging for push notifications
FCM_SERVER_KEY=your-fcm-server-key
FCM_SENDER_ID=your-fcm-sender-id
```

**Generate Strong JWT Secret:**
```powershell
# Run in PowerShell to generate secure secret
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

---

### 2. MongoDB Atlas Setup (Recommended for Production)

**Why Atlas?**
- ✅ Automatic backups (point-in-time recovery)
- ✅ Built-in security (encryption at rest/in transit)
- ✅ Free tier available (512MB)
- ✅ Access from anywhere with IP whitelist
- ✅ Professional monitoring and alerts

**Setup Steps:**

1. **Create Account**: https://www.mongodb.com/cloud/atlas/register
2. **Create Cluster**: 
   - Choose "Free Shared" tier (M0)
   - Select region closest to your users
   - Cluster name: `MyMedicineCluster`
3. **Create Database User**:
   - Username: `mymedicine_admin`
   - Password: Generate strong password (save it!)
   - Role: `Atlas admin` or `Read and write to any database`
4. **Network Access**:
   - Add IP: `0.0.0.0/0` (allow from anywhere) for testing
   - For production: Add specific IP addresses only
5. **Get Connection String**:
   - Click "Connect" → "Connect your application"
   - Copy connection string
   - Replace `<password>` with your database user password

---

### 3. Access Control & Monitoring

#### A. Create Admin API Endpoints

Add admin routes for user management:

**backend/routes/admin.js** (Create this file):
```javascript
const express = require('express');
const router = express.Router();
const User = require('../models/User');
const LinkInvitation = require('../models/LinkInvitation');

// Admin middleware - verify admin credentials
const adminAuth = (req, res, next) => {
  const adminKey = req.headers['x-admin-key'];
  if (adminKey !== process.env.ADMIN_API_KEY) {
    return res.status(403).json({ message: 'Unauthorized' });
  }
  next();
};

// Get all users (without passwords)
router.get('/users', adminAuth, async (req, res) => {
  try {
    const users = await User.find()
      .select('-password') // Exclude password field
      .sort({ createdAt: -1 });
    
    res.json({
      success: true,
      count: users.length,
      users
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

// Get user statistics
router.get('/stats', adminAuth, async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const patientsCount = await User.countDocuments({ userType: 'patient' });
    const caregiversCount = await User.countDocuments({ userType: 'caregiver' });
    const linkedPatientsCount = await User.countDocuments({ 
      userType: 'patient',
      caregiverId: { $ne: null }
    });
    const pendingInvitations = await LinkInvitation.countDocuments({ 
      status: 'pending' 
    });
    
    res.json({
      success: true,
      stats: {
        totalUsers,
        patients: patientsCount,
        caregivers: caregiversCount,
        linkedPatients: linkedPatientsCount,
        unlinkedPatients: patientsCount - linkedPatientsCount,
        pendingInvitations,
        linkedPercentage: ((linkedPatientsCount / patientsCount) * 100).toFixed(1)
      }
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

// Get user by username (admin view)
router.get('/user/:username', adminAuth, async (req, res) => {
  try {
    const user = await User.findOne({ username: req.params.username.toLowerCase() })
      .select('-password')
      .populate('caregiverId', 'name username')
      .populate('patientIds', 'name username');
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json({ success: true, user });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

// Delete user (admin only)
router.delete('/user/:username', adminAuth, async (req, res) => {
  try {
    const user = await User.findOneAndDelete({ 
      username: req.params.username.toLowerCase() 
    });
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json({ 
      success: true, 
      message: `User ${user.username} deleted successfully` 
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
```

**Update backend/server.js** to include admin routes:
```javascript
// After other route imports
const adminRoutes = require('./routes/admin');

// After other routes
app.use('/api/admin', adminRoutes);
```

**Add to backend/.env**:
```bash
# Admin API Key - Generate strong random string
ADMIN_API_KEY=your-super-secret-admin-key-here-change-this
```

#### B. Admin Access Examples

**Get All Users:**
```powershell
$adminKey = "your-super-secret-admin-key-here"
$headers = @{"x-admin-key" = $adminKey}

Invoke-WebRequest -Uri "http://localhost:5000/api/admin/users" `
  -Method GET `
  -Headers $headers | Select-Object -ExpandProperty Content | ConvertFrom-Json | Format-List
```

**Get Statistics:**
```powershell
Invoke-WebRequest -Uri "http://localhost:5000/api/admin/stats" `
  -Method GET `
  -Headers $headers | Select-Object -ExpandProperty Content
```

**Get Specific User:**
```powershell
Invoke-WebRequest -Uri "http://localhost:5000/api/admin/user/ahmed123" `
  -Method GET `
  -Headers $headers | Select-Object -ExpandProperty Content
```

---

### 4. MongoDB Compass - GUI Database Management

**Download:** https://www.mongodb.com/try/download/compass

**Connect:**
1. Open MongoDB Compass
2. Connection String: `mongodb://localhost:27017` (local) or your Atlas URI
3. Click "Connect"

**What You Can Do:**
- ✅ View all users
- ✅ Search by username
- ✅ See relationships (caregiver links)
- ✅ View invitation codes
- ✅ Export data to CSV/JSON
- ✅ Create backups
- ❌ Cannot decrypt passwords (they're hashed permanently)

**Example Queries in Compass:**

Find all patients:
```json
{ "userType": "patient" }
```

Find patients without caregiver:
```json
{ "userType": "patient", "caregiverId": null }
```

Find specific user:
```json
{ "username": "ahmed123" }
```

---

### 5. Password Management

#### If User Forgets Password (Reset Feature)

**Add to backend/routes/auth.js**:
```javascript
// Password reset by admin (user provides username)
router.post('/reset-password', async (req, res) => {
  try {
    const { username, newPassword } = req.body;
    
    if (!username || !newPassword) {
      return res.status(400).json({ message: 'Username and new password required' });
    }
    
    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'Password must be at least 6 characters' });
    }
    
    const user = await User.findOne({ username: username.toLowerCase() });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    user.updatedAt = Date.now();
    await user.save();
    
    res.json({ 
      success: true, 
      message: 'Password reset successfully' 
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});
```

**Usage:**
```powershell
$body = @{
    username = "ahmed123"
    newPassword = "newpassword123"
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:5000/api/auth/reset-password" `
  -Method POST `
  -Headers @{"Content-Type"="application/json"} `
  -Body $body
```

---

### 6. Security Best Practices

#### A. Rate Limiting (Prevent Brute Force Attacks)

Install rate limiter:
```powershell
cd backend
npm install express-rate-limit
```

Add to **backend/server.js**:
```javascript
const rateLimit = require('express-rate-limit');

// Create limiter
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Max 100 requests per windowMs
  message: 'Too many requests, please try again later'
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5, // Max 5 login attempts per 15 minutes
  message: 'Too many login attempts, please try again later'
});

// Apply to all routes
app.use('/api/', limiter);

// Apply stricter limit to auth routes
app.use('/api/auth/login', authLimiter);
app.use('/api/auth/register', authLimiter);
```

#### B. HTTPS in Production (SSL/TLS)

When deploying:
- ✅ Use HTTPS (not HTTP)
- ✅ Get free SSL certificate from Let's Encrypt
- ✅ Most hosting providers (Heroku, AWS, etc.) provide this automatically

#### C. Input Validation & Sanitization

Already implemented ✅:
- Username length validation
- Password minimum length
- UserType enum validation

#### D. CORS Configuration

**Current:** Allows all origins (good for development)
**Production:** Restrict to your app only

Update **backend/server.js**:
```javascript
const cors = require('cors');

// For production - replace with your Flutter app's domain
const corsOptions = {
  origin: process.env.NODE_ENV === 'production' 
    ? 'https://yourdomain.com' 
    : '*',
  credentials: true
};

app.use(cors(corsOptions));
```

---

### 7. Backup Strategy

#### MongoDB Atlas (Automatic)
- ✅ Continuous backups every hour
- ✅ Point-in-time recovery (restore to any second)
- ✅ Snapshots retained for days/weeks based on tier

#### Local MongoDB (Manual)
```powershell
# Backup to file
mongodump --db mymedicine --out C:\backups\mymedicine-backup-2026-03-07

# Restore from backup
mongorestore --db mymedicine C:\backups\mymedicine-backup-2026-03-07\mymedicine
```

**Automate with scheduled task:**
Create `backup-script.ps1`:
```powershell
$date = Get-Date -Format "yyyy-MM-dd"
$backupPath = "C:\backups\mymedicine-$date"
mongodump --db mymedicine --out $backupPath
Write-Host "Backup completed: $backupPath"

# Optional: Upload to cloud storage (Google Drive, Dropbox, etc.)
```

---

### 8. Monitoring & Logging

#### A. Access Logs

Add to **backend/server.js**:
```javascript
const fs = require('fs');
const path = require('path');

// Create logs directory if it doesn't exist
const logsDir = path.join(__dirname, 'logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir);
}

// Log middleware
app.use((req, res, next) => {
  const logEntry = `${new Date().toISOString()} - ${req.method} ${req.url} - IP: ${req.ip}\n`;
  fs.appendFile(path.join(logsDir, 'access.log'), logEntry, (err) => {
    if (err) console.error('Logging error:', err);
  });
  next();
});
```

#### B. Error Tracking

Consider using services like:
- Sentry (error tracking)
- LogRocket (user session replay)
- Datadog (full monitoring)

---

## 🚀 Deployment Checklist

Before going live:

- [ ] Change JWT_SECRET to strong random string (64+ characters)
- [ ] Use MongoDB Atlas (not local MongoDB)
- [ ] Enable HTTPS/SSL
- [ ] Add rate limiting
- [ ] Configure CORS for your domain only
- [ ] Set up automated backups
- [ ] Add admin API endpoints with strong key
- [ ] Test password reset flow
- [ ] Set NODE_ENV=production
- [ ] Remove console.log() statements
- [ ] Add error logging service
- [ ] Document admin procedures
- [ ] Test disaster recovery (restore from backup)

---

## 📊 What Data You Can Access

### ✅ You CAN See:
- All usernames
- Full names
- Email addresses (if you add this field)
- User types (patient/caregiver)
- Account creation dates
- Login timestamps (if you add logging)
- Patient-caregiver relationships
- Invitation codes
- App usage statistics

### ❌ You CANNOT See:
- **Plain text passwords** (only hashed versions)
- This is CORRECT and REQUIRED for security
- Even you as admin cannot recover forgotten passwords
- Users must reset passwords, not retrieve them

---

## 🔒 Legal/Privacy Compliance

If storing medical data, consider:
- **HIPAA** (USA) - Health data protection
- **GDPR** (Europe) - User data rights
- **Local regulations** in your country

Requirements may include:
- User data export feature
- Account deletion feature
- Privacy policy
- Terms of service
- Data encryption at rest
- Audit logs

---

## Summary

**Your current setup is SECURE** ✅ (bcrypt + JWT)

**For production, you must:**
1. Generate strong JWT_SECRET
2. Use MongoDB Atlas (cloud)
3. Add admin API endpoints
4. Enable rate limiting
5. Set up monitoring

**MongoDB is sufficient** - it's used by major enterprises and handles millions of users.

**Next Steps:**
1. Follow Environment Variables section (#1)
2. Set up MongoDB Atlas (#2)
3. Add admin routes (#3)
4. Install MongoDB Compass (#4)
5. Test everything before launching
