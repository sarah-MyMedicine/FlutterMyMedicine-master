# Backend Integration Guide for MyMedicine Flutter App

## Overview

The MyMedicine app has been updated with **complete backend integration** capabilities. This guide explains how to:
1. Set up and run the backend server
2. Configure the Flutter app to use the backend
3. Update providers to sync with the backend
4. Deploy everything to production

---

## What Has Been Added

### 1. **API Service Client** (`lib/services/api_service.dart`)
A singleton service that handles all HTTP requests to your backend server. It includes methods for:
- Authentication (login, register, logout)
- Medications (CRUD operations)
- Blood Pressure (tracking and history)
- Blood Sugar (tracking and history)
- Appointments (scheduling)
- Adherence (tracking medication compliance)

### 2. **Authentication Service** (`lib/services/auth_service.dart`)
A Provider-based service that manages user authentication state, including:
- User login and registration
- Token management
- Error handling
- Loading states

### 3. **Backend Documentation** (`BACKEND_SETUP.md`)
Comprehensive guide for setting up a Node.js/Express backend with MongoDB, including:
- Project setup instructions
- Database models
- API routes
- Middleware
- Testing with Postman

### 4. **Example Provider** (`lib/providers/MEDICATION_PROVIDER_WITH_BACKEND_EXAMPLE.dart`)
Shows how to update existing providers to sync with the backend.

---

## Quick Start

### Step 1: Update the Backend URL

Edit `lib/services/api_service.dart`:

```dart
static const String _baseUrl = 'http://192.168.1.100:5000/api';
// ↑ Change this to your backend URL
// For local testing: 'http://localhost:5000/api'
// For mobile on your network: 'http://192.168.x.x:5000/api' (your machine's IP)
```

### Step 2: Create Your Backend

Follow the instructions in `BACKEND_SETUP.md`:

```bash
mkdir mymedicine-backend
cd mymedicine-backend
npm init -y
npm install express cors dotenv bcryptjs jsonwebtoken mongoose

# Create files as per BACKEND_SETUP.md
# ...

npm run dev
```

### Step 3: Update Providers

Create a new provider file based on `MEDICATION_PROVIDER_WITH_BACKEND_EXAMPLE.dart`:

```dart
// In your provider, add:
Future<void> loadFromBackend(BuildContext context) async {
  final medications = await _apiService.getMedications();
  _items.clear();
  _items.addAll(medications);
  notifyListeners();
}

Future<void> addToBackend({required String name, ...}) async {
  final result = await _apiService.addMedication(...);
  _items.add(result);
  notifyListeners();
}
```

### Step 4: Update Pages to Show Login

Create a login page if you don't have one:

```dart
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.isAuthenticated) {
          return HomePage(); // Navigate to main app
        }

        return Scaffold(
          appBar: AppBar(title: Text('Login')),
          body: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Password'),
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: authService.isLoading
                      ? null
                      : () async {
                          final success = await authService.login(
                            email: emailController.text,
                            password: passwordController.text,
                          );
                          if (success) {
                            // Load data from backend
                            if (mounted) {
                              Provider.of<MedicationProvider>(context, listen: false)
                                  .loadFromBackend(context);
                            }
                          }
                        },
                  child: authService.isLoading
                      ? CircularProgressIndicator()
                      : Text('Login'),
                ),
                if (authService.errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      authService.errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter App (Android/iOS)                │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Pages ──→ Providers ──→ ApiService ──→ Backend API         │
│             ↓                              ↓                 │
│          Local State              HTTP Requests             │
│          Notifications            Authentication            │
│          Storage                  Data Persistence          │
│                                                               │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    ┌──────────────┐
                    │   Backend    │
                    │ (Node.js +   │
                    │  MongoDB)    │
                    └──────────────┘
```

---

## API Endpoints Reference

### Authentication
```
POST /api/auth/register
POST /api/auth/login
POST /api/auth/logout
```

### Medications
```
GET    /api/medications              (Get all)
POST   /api/medications              (Add new)
PUT    /api/medications/:id          (Update)
DELETE /api/medications/:id          (Delete)
```

### Blood Pressure
```
GET    /api/blood-pressure           (Get all)
POST   /api/blood-pressure           (Add new)
```

### Blood Sugar
```
GET    /api/blood-sugar              (Get all)
POST   /api/blood-sugar              (Add new)
```

### Appointments
```
GET    /api/appointments             (Get all)
POST   /api/appointments             (Add new)
DELETE /api/appointments/:id         (Delete)
```

### Adherence
```
POST   /api/adherence/record         (Record taken)
GET    /api/adherence/stats          (Get stats)
```

---

## Testing with Postman

### 1. Register a User
- **Method:** POST
- **URL:** `http://localhost:5000/api/auth/register`
- **Body (JSON):**
```json
{
  "email": "test@example.com",
  "password": "password123",
  "name": "Test User"
}
```
- **Copy the token from response**

### 2. Login
- **Method:** POST
- **URL:** `http://localhost:5000/api/auth/login`
- **Body (JSON):**
```json
{
  "email": "test@example.com",
  "password": "password123"
}
```

### 3. Add Medication
- **Method:** POST
- **URL:** `http://localhost:5000/api/medications`
- **Headers:** `Authorization: Bearer <your_token>`
- **Body (JSON):**
```json
{
  "name": "Aspirin",
  "dose": "100mg",
  "intervalHours": 12,
  "nextDose": "2024-01-28T10:00:00Z",
  "notes": "Take with food"
}
```

---

## Error Handling

### Common Errors and Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| "Connection refused" | Backend not running | Start backend with `npm run dev` |
| "Invalid credentials" | Wrong email/password | Check credentials, create new account |
| "Invalid token" | Token expired or invalid | Login again to get new token |
| "Not authenticated" | No token in headers | Ensure user is logged in |
| "CORS error" | Backend CORS not configured | Check CORS settings in `server.js` |

### Implementing Retry Logic

```dart
Future<T> _withRetry<T>(Future<T> Function() operation, {int retries = 3}) async {
  for (int i = 0; i < retries; i++) {
    try {
      return await operation();
    } catch (e) {
      if (i == retries - 1) rethrow;
      await Future.delayed(Duration(seconds: 2 * (i + 1))); // Exponential backoff
    }
  }
  throw Exception('All retries failed');
}

// Usage
final medications = await _withRetry(() => _apiService.getMedications());
```

---

## Offline Support

Add offline capabilities to your app:

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';

class OfflineDataService {
  // Cache data locally
  Future<void> cacheData(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
  }

  Future<dynamic> getCachedData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);
    return data != null ? jsonDecode(data) : null;
  }

  // Check connectivity
  Future<bool> isOnline() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
```

---

## Performance Optimization

### 1. Pagination
```dart
Future<List<Map<String, dynamic>>> getMedicationsPaginated(int page, int pageSize) async {
  // Pass page and pageSize to backend
  // Backend returns: { data: [...], total: X, page: Y, pageSize: Z }
}
```

### 2. Caching
```dart
class CachedApiService {
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTime = {};

  Future<T> getCachedOrFetch<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration cacheDuration = const Duration(minutes: 5),
  }) async {
    if (_cache.containsKey(key)) {
      final lastFetch = _cacheTime[key];
      if (lastFetch != null && DateTime.now().difference(lastFetch) < cacheDuration) {
        return _cache[key] as T;
      }
    }

    final data = await fetcher();
    _cache[key] = data;
    _cacheTime[key] = DateTime.now();
    return data;
  }
}
```

### 3. Background Sync
```dart
// Sync data periodically in the background
Future<void> syncDataInBackground() {
  return BackgroundFetch.registerHeadlessTask((taskId) async {
    try {
      // Load latest data from backend
      final medications = await ApiService().getMedications();
      // Update local state
    } catch (e) {
      debugPrint('Background sync error: $e');
    }
  });
}
```

---

## Deployment

### Backend Deployment (Heroku Example)

```bash
# 1. Create Heroku account and install CLI
# 2. Login to Heroku
heroku login

# 3. Create app
heroku create mymedicine-backend

# 4. Set environment variables
heroku config:set JWT_SECRET=your_secret_key
heroku config:set MONGODB_URI=your_mongo_atlas_uri

# 5. Deploy
git push heroku main

# 6. View logs
heroku logs --tail
```

### Update Flutter App for Production

```dart
// In api_service.dart
static const String _baseUrl = 'https://your-backend.herokuapp.com/api';
// ↑ Use HTTPS in production, not HTTP
```

### Mobile App Deployment

- **Android:** Update `versionCode` in `build.gradle`, build release APK/AAB
- **iOS:** Update `CFBundleShortVersionString`, build release IPA

---

## Security Best Practices

1. **Never commit secrets to version control**
   - Use `.env` files (git-ignored)
   - Use secure environment variable management

2. **Always use HTTPS in production**
   - Never send tokens over HTTP

3. **Validate all input on the backend**
   - Don't trust client-side validation alone

4. **Implement rate limiting**
   ```javascript
   const rateLimit = require('express-rate-limit');
   
   app.use(rateLimit({
     windowMs: 15 * 60 * 1000, // 15 minutes
     max: 100 // limit each IP to 100 requests per windowMs
   }));
   ```

5. **Use strong JWT secrets**
   - Generate with: `require('crypto').randomBytes(32).toString('hex')`

6. **Implement CORS correctly**
   ```javascript
   app.use(cors({
     origin: ['https://yourdomain.com', 'https://www.yourdomain.com'],
     credentials: true
   }));
   ```

---

## Monitoring and Logging

### Backend Logging
```javascript
// Use winston or similar for production logging
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});
```

### App Analytics
```dart
// Track important events
class AnalyticsService {
  void logMedicationAdded(String name) {
    // Send to analytics service
  }

  void logAdherence(String medicationName, bool taken) {
    // Track user adherence
  }
}
```

---

## Next Steps

1. **Set up the backend** following BACKEND_SETUP.md
2. **Update all providers** to use ApiService
3. **Create a login page** for user authentication
4. **Test thoroughly** with Postman before releasing
5. **Deploy to production** with proper security
6. **Monitor** user feedback and errors
7. **Implement caching** and offline support as needed
8. **Optimize performance** based on real usage patterns

---

## Support and Resources

- [Node.js Documentation](https://nodejs.org/docs/)
- [Express.js Guide](https://expressjs.com/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Flutter HTTP Package](https://pub.dev/packages/http)
- [Provider Package](https://pub.dev/packages/provider)

---

## Troubleshooting Checklist

- [ ] Backend is running on the correct port
- [ ] `MONGODB_URI` is set correctly
- [ ] `JWT_SECRET` is defined in `.env`
- [ ] CORS is configured in backend
- [ ] ApiService URL matches backend URL
- [ ] Token is being saved/loaded correctly
- [ ] All required fields are being sent in requests
- [ ] Backend responses match expected format
