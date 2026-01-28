# Backend Quick Reference Card

## 🚀 Getting Started in 5 Minutes

### 1. Update Backend URL
```dart
// lib/services/api_service.dart - Line ~10
static const String _baseUrl = 'http://localhost:5000/api';
```

### 2. Start Backend
```bash
cd mymedicine-backend
npm run dev
# Server runs on http://localhost:5000
```

### 3. Run Flutter App
```bash
flutter pub get
flutter run
```

---

## 🔗 Key Classes

### ApiService (Singleton)
```dart
final api = ApiService();
await api.init();

// Authentication
await api.login(email: '...', password: '...');
await api.register(email: '...', password: '...', name: '...');
await api.logout();

// Medications
await api.getMedications();
await api.addMedication(...);
await api.updateMedication(...);
await api.deleteMedication(...);
```

### AuthService (Provider)
```dart
Consumer<AuthService>(
  builder: (context, authService, _) {
    if (!authService.isAuthenticated) return LoginPage();
    return HomePage();
  }
)

// Check status
authService.isAuthenticated
authService.isLoading
authService.errorMessage
```

---

## 📡 Common API Calls

### Login User
```dart
final authService = Provider.of<AuthService>(context, listen: false);
await authService.login(
  email: 'user@example.com',
  password: 'password123',
);
```

### Load Medications
```dart
final api = ApiService();
final meds = await api.getMedications();
```

### Add Medication
```dart
await api.addMedication(
  name: 'Aspirin',
  dose: '100mg',
  intervalHours: 12,
  nextDose: DateTime.now().add(Duration(hours: 12)),
  notes: 'Take with food',
);
```

### Record Adherence
```dart
await api.recordMedicationTaken(
  medicationId: medId,
  timestamp: DateTime.now(),
);
```

---

## 🗄️ MongoDB Models

```javascript
// User
{
  name: String,
  email: String,
  password: String (hashed),
  createdAt: Date
}

// Medication
{
  userId: ObjectId,
  name: String,
  dose: String,
  intervalHours: Number,
  nextDose: Date,
  notes: String,
  quantity: Number,
  isArchived: Boolean
}

// Adherence
{
  userId: ObjectId,
  medicationId: ObjectId,
  medicationName: String,
  timestamp: Date
}
```

---

## 🧪 Postman Testing

### Register
```
POST http://localhost:5000/api/auth/register
Body:
{
  "email": "test@example.com",
  "password": "pass123",
  "name": "Test User"
}
Response: { "token": "...", "userId": "..." }
```

### Login
```
POST http://localhost:5000/api/auth/login
Body:
{
  "email": "test@example.com",
  "password": "pass123"
}
Response: { "token": "...", "userId": "...", "name": "..." }
```

### Get Medications
```
GET http://localhost:5000/api/medications
Headers:
  Authorization: Bearer <token>
Response: [{ "id": "...", "name": "...", ... }]
```

---

## 📝 Environment Variables (.env)

```
PORT=5000
MONGODB_URI=mongodb://localhost:27017/mymedicine
JWT_SECRET=your_super_secret_key_change_this
JWT_EXPIRES_IN=7d
NODE_ENV=development
```

---

## 🔄 Data Flow Example

```
User taps "Add Medication"
    ↓
MedicationForm validates input
    ↓
MedicationProvider.addToBackend() called
    ↓
ApiService.addMedication() sends POST request
    ↓
Backend validates and saves to MongoDB
    ↓
Returns created medication with ID
    ↓
Provider adds to local _items list
    ↓
UI rebuilds with new medication
    ↓
NotificationService schedules reminders
```

---

## ⚠️ Common Issues

| Issue | Solution |
|-------|----------|
| "Connection refused" | Backend not running - `npm run dev` |
| "Invalid credentials" | Check email/password, register new user |
| "Token expired" | User needs to login again |
| "CORS error" | Check CORS config in backend server.js |
| "No medications shown" | Call `loadFromBackend()` after login |

---

## 📱 Android Emulator Networking

To access your local backend from Android Emulator:

```dart
// Use the special IP for emulator
static const String _baseUrl = 'http://10.0.2.2:5000/api';
```

For physical devices on local network:
```dart
static const String _baseUrl = 'http://192.168.1.100:5000/api';
// ↑ Replace with your machine's local IP
```

---

## 🔐 Security Headers

All requests automatically include:
```
Content-Type: application/json
Authorization: Bearer <token>  (if logged in)
```

---

## 📚 File Structure

```
mymedicine-backend/
├── server.js
├── .env
├── models/
│   ├── User.js
│   ├── Medication.js
│   ├── BloodPressure.js
│   ├── BloodSugar.js
│   ├── Appointment.js
│   └── Adherence.js
├── routes/
│   ├── auth.js
│   ├── medications.js
│   ├── blood-pressure.js
│   ├── blood-sugar.js
│   ├── appointments.js
│   └── adherence.js
├── middleware/
│   └── auth.js
└── package.json
```

---

## 🚢 Deployment Checklist

- [ ] Update `_baseUrl` to production URL (HTTPS)
- [ ] Change `JWT_SECRET` to strong random string
- [ ] Set `NODE_ENV=production`
- [ ] Enable CORS for your domain only
- [ ] Set up database backups
- [ ] Configure error logging
- [ ] Test authentication flow
- [ ] Test all API endpoints
- [ ] Deploy backend (Heroku, Railway, AWS, etc.)
- [ ] Update app version code
- [ ] Build and sign APK/IPA
- [ ] Submit to stores

---

## 💡 Pro Tips

1. **Test Locally First**
   - Run backend on localhost
   - Test all endpoints with Postman
   - Then deploy to production

2. **Use Proper Error Handling**
   - Show user-friendly error messages
   - Log errors for debugging
   - Implement retry logic

3. **Implement Caching**
   - Cache medications list
   - Reduce API calls
   - Better user experience

4. **Add Offline Support**
   - Save data locally
   - Sync when online
   - Better app reliability

5. **Monitor Performance**
   - Track API response times
   - Monitor server logs
   - Optimize slow endpoints

---

## 🆘 Getting Help

1. Check `BACKEND_INTEGRATION_GUIDE.md` for detailed info
2. See `BACKEND_SETUP.md` for step-by-step setup
3. Review `BACKEND_SERVER_EXAMPLE.js` for code examples
4. Check example provider: `MEDICATION_PROVIDER_WITH_BACKEND_EXAMPLE.dart`

---

## ✅ Checklist Before Launch

- [ ] Backend setup and running
- [ ] Database connected
- [ ] All API endpoints tested
- [ ] Authentication working
- [ ] Flutter app connected to backend
- [ ] Login page implemented
- [ ] Providers syncing with backend
- [ ] Error handling in place
- [ ] Tested on physical device
- [ ] Security measures implemented
- [ ] Documentation updated
- [ ] Ready for production deployment

**You're all set! Happy coding! 🎉**
