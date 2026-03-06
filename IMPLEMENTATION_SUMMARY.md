# Backend and Navigation Setup - Quick Guide

## ✅ Task 1: Backend API Endpoints Complete

Created a complete Node.js/Express backend with MongoDB support:

### Backend Files Created:
```
backend/
├── server.js                 # Main server file
├── package.json             # Dependencies
├── .env.example            # Environment template
├── .gitignore             # Git ignore rules
├── README.md              # Full documentation
├── models/
│   ├── User.js           # User model (patient/caregiver)
│   └── LinkInvitation.js # Invitation code model
├── routes/
│   ├── auth.js           # Register/login endpoints
│   └── caregiver.js      # Caregiver linking endpoints
└── middleware/
    └── auth.js           # JWT authentication

```

### Implemented Endpoints:

**Authentication** (`/api/auth`)
- `POST /register` - Create new patient or caregiver account
- `POST /login` - Login with username/password
- `POST /logout` - Logout

**Caregiver Management** (`/api/caregiver`)
- `POST /generate-invitation` - Generate 6-digit invitation code
- `GET /invitations/:username` - Get pending invitations
- `POST /accept-invitation` - Accept and link caregiver
- `POST /reject-invitation` - Reject invitation
- `GET /patients/:caregiverUsername` - Get linked patients
- `GET /caregiver/:patientUsername` - Get linked caregiver
- `POST /unlink` - Remove patient-caregiver link
- `POST /notify-missed-dose` - Send missed dose notification

### Database Schema:
- **User**: username, password, name, userType, caregiverId, patientIds, fcmToken
- **LinkInvitation**: invitationCode, patientId, patientName, status, expiresAt

---

## ✅ Task 2: Navigation Routing Complete

Updated Flutter app with authentication flow:

### Changes to `lib/main.dart`:
1. Added imports for new pages:
   - `LoginPage`
   - `RegisterPage`
   - `CaregiverLinkPage`

2. Added `UserProvider` initialization and storage loading

3. Updated initial page logic:
   - Check if user is logged in (priority)
   - Check if language is selected
   - Check if onboarding is completed
   - Otherwise show home

4. Added routes to `MaterialApp`:
   - `/login` → LoginPage
   - `/register` → RegisterPage
   - `/caregiver-link` → CaregiverLinkPage
   - `/home` → HomePage
   - `/language` → LanguageSelectionPage
   - `/onboarding` → OnboardingPage

### User Authentication Flow:
```
Launch App
    ↓
Load UserProvider from Storage
    ↓
Is user logged in?
    ├─ NO → LoginPage
    │        ├─ Register? → RegisterPage
    │        └─ Login → Load home
    └─ YES → Is language selected?
              ├─ NO → LanguageSelectionPage
              └─ YES → Is onboarding done?
                       ├─ NO → OnboardingPage
                       └─ YES → HomePage
```

---

## 🚀 Next Steps - Quick Setup

### Backend Setup:

1. **Install Dependencies**
   ```bash
   cd backend
   npm install
   ```

2. **Create .env file**
   ```bash
   cp .env.example .env
   ```

3. **Configure MongoDB**
   - Option A: Local (run `mongod`)
   - Option B: MongoDB Atlas (cloud service)

4. **Start Server**
   ```bash
   npm run dev
   ```
   Server runs on `http://localhost:5000`

### Flutter App Configuration:

1. **Update API URL in `lib/services/api_service.dart`**
   ```dart
   // For Android Emulator:
   static const String _baseUrl = 'http://10.0.2.2:5000/api';
   
   // For iOS Simulator:
   static const String _baseUrl = 'http://localhost:5000/api';
   
   // For physical device (replace with your IP):
   static const String _baseUrl = 'http://192.168.x.x:5000/api';
   ```

2. **Rebuild and Run**
   ```bash
   flutter pub get
   flutter run
   ```

---

## Files Overview

### Frontend Changes:
- ✅ `lib/main.dart` - Updated with new routes and login logic
- ✅ `lib/services/api_service.dart` - Added caregiver API methods
- ✅ `lib/services/auth_service.dart` - Updated for username/password
- ✅ `lib/Pages/login_page.dart` - Created (NEW)
- ✅ `lib/Pages/register_page.dart` - Created (NEW)
- ✅ `lib/Pages/caregiver_link_page.dart` - Created (NEW)
- ✅ `lib/providers/user_provider.dart` - Created (NEW)
- ✅ `lib/utils/translations.dart` - Added 50+ new translation keys

### Backend Files:
- ✅ `backend/server.js` - Express server
- ✅ `backend/package.json` - Dependencies
- ✅ `backend/models/User.js` - User model
- ✅ `backend/models/LinkInvitation.js` - Invitation model
- ✅ `backend/routes/auth.js` - Auth endpoints
- ✅ `backend/routes/caregiver.js` - Caregiver endpoints
- ✅ `backend/middleware/auth.js` - JWT verification
- ✅ `backend/README.md` - Full documentation
- ✅ `backend/.env.example` - Environment template

---

## Testing the Endpoints

### Using curl or Postman:

**Register:**
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "ahmed123",
    "password": "password123",
    "name": "Ahmed Ali",
    "userType": "patient"
  }'
```

**Login:**
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "ahmed123",
    "password": "password123"
  }'
```

**Generate Invitation** (replace TOKEN with JWT from login):
```bash
curl -X POST http://localhost:5000/api/caregiver/generate-invitation \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username": "ahmed123"}'
```

---

## Current Status

| Feature | Status | Notes |
|---------|--------|-------|
| User Registration (username/password) | ✅ Complete | No email/phone needed |
| User Login | ✅ Complete | JWT token generation |
| Patient Account Type | ✅ Complete | Can generate invitations |
| Caregiver Account Type | ✅ Complete | Can accept invitations |
| Invitation Code Generation | ✅ Complete | 6-digit codes, 24hr expiry |
| Patient-Caregiver Linking | ✅ Complete | Bi-directional relationships |
| Navigation Routing | ✅ Complete | Login required to access app |
| UI Pages for Caregiver | ✅ Complete | Invitations, patients, notifications |
| Translation Keys | ✅ Complete | Arabic & English support |
| **Missed Dose Detection** | 🔄 **Next Step** | Track consecutive missed doses |
| **Caregiver Notifications** | 🔄 **Next Step** | Send to caregiver at 2 missed |

---

## Troubleshooting

**"Cannot GET /api/auth/register"**
- Backend not running. Run `npm run dev` in backend directory

**"Connection refused"**
- Backend server not started or wrong IP/port in api_service.dart

**"MongoDB connection failed"**
- MongoDB not running. Run `mongod` (Windows) or `brew services start mongodb-community` (Mac)

**"Token error"**
- Must login first to get JWT token before accessing caregiver endpoints

For full documentation, see:
- `backend/README.md` - Complete API documentation
- `lib/Pages/caregiver_link_page.dart` - UI implementation
- `lib/services/api_service.dart` - API integration
