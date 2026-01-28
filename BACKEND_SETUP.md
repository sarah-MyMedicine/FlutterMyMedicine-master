# MyMedicine Backend Setup Guide

This guide will help you set up the backend server for the MyMedicine Flutter app.

## Option 1: Quick Start with Node.js/Express (Recommended)

### Prerequisites
- Node.js (v16+) and npm installed
- MongoDB (local or cloud Atlas)
- A code editor (VS Code recommended)

### Step 1: Create Backend Project Directory

```bash
mkdir mymedicine-backend
cd mymedicine-backend
npm init -y
```

### Step 2: Install Dependencies

```bash
npm install express cors dotenv bcryptjs jsonwebtoken mongoose axios
npm install --save-dev nodemon
```

### Step 3: Create `.env` file

Create a file named `.env` in the root directory:

```env
PORT=5000
MONGODB_URI=mongodb://localhost:27017/mymedicine
# or for MongoDB Atlas:
# MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/mymedicine?retryWrites=true&w=majority

JWT_SECRET=your_super_secret_jwt_key_here_change_this
JWT_EXPIRES_IN=7d
NODE_ENV=development
```

### Step 4: Create `server.js`

See the provided `server.js` template in this directory.

### Step 5: Create MongoDB Models

Create a `models` directory and add the following files:

#### models/User.js
```javascript
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true, lowercase: true },
  password: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

userSchema.methods.comparePassword = async function(password) {
  return await bcrypt.compare(password, this.password);
};

module.exports = mongoose.model('User', userSchema);
```

#### models/Medication.js
```javascript
const mongoose = require('mongoose');

const medicationSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true },
  dose: { type: String, required: true },
  intervalHours: { type: Number, required: true },
  nextDose: { type: Date, required: true },
  notes: String,
  quantity: Number,
  remainingDoses: Number,
  isArchived: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Medication', medicationSchema);
```

#### models/BloodPressure.js
```javascript
const mongoose = require('mongoose');

const bloodPressureSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  systolic: { type: Number, required: true },
  diastolic: { type: Number, required: true },
  timestamp: { type: Date, default: Date.now },
  notes: String,
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('BloodPressure', bloodPressureSchema);
```

#### models/BloodSugar.js
```javascript
const mongoose = require('mongoose');

const bloodSugarSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  value: { type: Number, required: true },
  unit: { type: String, enum: ['mg/dL', 'mmol/L'], required: true },
  timestamp: { type: Date, default: Date.now },
  notes: String,
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('BloodSugar', bloodSugarSchema);
```

#### models/Appointment.js
```javascript
const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true },
  dateTime: { type: Date, required: true },
  location: String,
  doctorName: String,
  notes: String,
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Appointment', appointmentSchema);
```

#### models/Adherence.js
```javascript
const mongoose = require('mongoose');

const adherenceSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  medicationId: { type: mongoose.Schema.Types.ObjectId, ref: 'Medication', required: true },
  medicationName: { type: String, required: true },
  dose: { type: String, required: true },
  timestamp: { type: Date, default: Date.now },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Adherence', adherenceSchema);
```

### Step 6: Create Routes

Create a `routes` directory and add API endpoints:

#### routes/auth.js
```javascript
const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');

router.post('/register', async (req, res) => {
  try {
    const { email, password, name } = req.body;
    
    let user = await User.findOne({ email });
    if (user) return res.status(400).json({ message: 'User already exists' });
    
    user = new User({ email, password, name });
    await user.save();
    
    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRES_IN
    });
    
    res.status(201).json({ 
      token, 
      userId: user._id,
      message: 'User registered successfully' 
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    const user = await User.findOne({ email });
    if (!user) return res.status(401).json({ message: 'Invalid credentials' });
    
    const isMatch = await user.comparePassword(password);
    if (!isMatch) return res.status(401).json({ message: 'Invalid credentials' });
    
    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRES_IN
    });
    
    res.json({ 
      token, 
      userId: user._id,
      name: user.name,
      email: user.email,
      message: 'Login successful' 
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.post('/logout', (req, res) => {
  res.json({ message: 'Logout successful' });
});

module.exports = router;
```

#### routes/medications.js
```javascript
const express = require('express');
const router = express.Router();
const Medication = require('../models/Medication');
const auth = require('../middleware/auth');

// Get all medications
router.get('/', auth, async (req, res) => {
  try {
    const medications = await Medication.find({ userId: req.userId });
    res.json(medications);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Add medication
router.post('/', auth, async (req, res) => {
  try {
    const { name, dose, intervalHours, nextDose, notes, quantity } = req.body;
    
    const medication = new Medication({
      userId: req.userId,
      name,
      dose,
      intervalHours,
      nextDose,
      notes,
      quantity,
      remainingDoses: quantity
    });
    
    await medication.save();
    res.status(201).json(medication);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Update medication
router.put('/:id', auth, async (req, res) => {
  try {
    const { name, dose, intervalHours, nextDose, notes, quantity } = req.body;
    
    const medication = await Medication.findByIdAndUpdate(
      req.params.id,
      { name, dose, intervalHours, nextDose, notes, quantity, updatedAt: Date.now() },
      { new: true }
    );
    
    res.json(medication);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Delete medication
router.delete('/:id', auth, async (req, res) => {
  try {
    await Medication.findByIdAndDelete(req.params.id);
    res.json({ message: 'Medication deleted' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
```

### Step 7: Create Middleware

#### middleware/auth.js
```javascript
const jwt = require('jsonwebtoken');

const auth = (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ message: 'No token provided' });
    
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;
    next();
  } catch (error) {
    res.status(401).json({ message: 'Invalid token' });
  }
};

module.exports = auth;
```

### Step 8: Update `package.json` scripts

```json
{
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  }
}
```

### Step 9: Run the Server

```bash
# Development
npm run dev

# Production
npm start
```

The server will run on `http://localhost:5000`

## Option 2: Use Firebase/Supabase

If you prefer a managed backend:

### Firebase Setup
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project
3. Enable Authentication (Email/Password)
4. Enable Firestore Database
5. Update `ApiService` to use Firebase SDK

### Supabase Setup
1. Go to [Supabase](https://supabase.com)
2. Create a new project
3. Enable PostgreSQL and Auth
4. Update `ApiService` to use Supabase client

## Testing the Backend

### Using Postman

1. **Register User**
   - Method: POST
   - URL: `http://localhost:5000/api/auth/register`
   - Body (JSON):
   ```json
   {
     "email": "user@example.com",
     "password": "password123",
     "name": "John Doe"
   }
   ```

2. **Login**
   - Method: POST
   - URL: `http://localhost:5000/api/auth/login`
   - Body (JSON):
   ```json
   {
     "email": "user@example.com",
     "password": "password123"
   }
   ```

3. **Add Medication**
   - Method: POST
   - URL: `http://localhost:5000/api/medications`
   - Headers: `Authorization: Bearer <token>`
   - Body (JSON):
   ```json
   {
     "name": "Aspirin",
     "dose": "100mg",
     "intervalHours": 12,
     "nextDose": "2024-01-28T10:00:00Z",
     "notes": "Take with food"
   }
   ```

## Updating the Flutter App

### 1. Update `main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API and Auth services
  await ApiService().init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        // ... other providers
      ],
      child: MyApp(),
    ),
  );
}
```

### 2. Update Backend URL

In `lib/services/api_service.dart`, change:
```dart
static const String _baseUrl = 'http://192.168.x.x:5000/api';
```

Use your machine's local IP for testing on mobile devices.

## Deployment

### Backend Deployment Options
- **Heroku**: Easy free tier with buildpacks
- **Railway**: Simple, modern alternative to Heroku
- **AWS**: EC2, ECS, Lambda for scalability
- **DigitalOcean**: Affordable VPS hosting
- **Render**: Free tier available

### Database Deployment
- **MongoDB Atlas**: Cloud hosting for MongoDB (free tier)
- **Supabase**: Managed PostgreSQL with built-in auth

## Security Checklist

- [ ] Change JWT_SECRET to a strong random string
- [ ] Use HTTPS in production
- [ ] Enable CORS properly (whitelist your app domain)
- [ ] Validate all input on the backend
- [ ] Use environment variables for sensitive data
- [ ] Implement rate limiting
- [ ] Add request logging and monitoring
- [ ] Regular security updates
- [ ] Database backups

## Troubleshooting

### Connection Issues
- Check if backend server is running
- Verify backend URL in `ApiService`
- Check firewall/network settings
- For mobile testing, use your machine's local IP

### Authentication Issues
- Verify JWT token expiration
- Check token storage in SharedPreferences
- Ensure CORS is configured properly

### Data Sync Issues
- Add error handling and retry logic
- Implement offline support with local caching
- Use proper error messages for debugging

## Next Steps

1. Implement remaining API endpoints (blood pressure, blood sugar, appointments)
2. Add data validation on the backend
3. Implement data sync/offline capabilities
4. Add push notifications integration
5. Implement data backup and recovery
