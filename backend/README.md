# MyMedicine Backend API

Backend API server for the MyMedicine Flutter app, built with Node.js, Express.js, and Firebase Admin/Firestore.

## Features

- User authentication with JWT (username/password)
- Firebase custom-token authentication support
- Patient and Caregiver account types
- Caregiver invitation system with time-limited codes
- Patient-Caregiver linking and unlinking
- Missed dose notifications
- Firestore-backed patient data storage
- Google sign-in bridge through Firebase Authentication

## Prerequisites

- Node.js (v14 or higher)
- npm or yarn
- Firebase project with Firestore enabled
- Firebase Admin service account credentials

## Installation

## Enable Firestore

1. Open Firebase Console and select your project.
2. Go to Build > Firestore Database.
3. Click Create database.
4. Choose Production mode if this is your real project. Choose Test mode only for temporary local testing.
5. Pick a Firestore region close to your backend host. This cannot be changed later.
6. Finish creation and wait until the database status becomes active.
7. Go to Project settings > Service accounts.
8. Create or select a Firebase Admin service account.
9. Generate a private key JSON file.
10. Put the credentials into this backend using one of these environment variables:

```env
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
```

or

```env
FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account",...}
```

11. From the backend folder, verify Firestore access:

```bash
npm run check:firestore
```

If that command succeeds, Firestore is enabled correctly for this backend.

### 1. Clone the repository

```bash
cd backend
npm install
```

### 2. Set up environment variables

Copy `.env.example` to `.env` and configure your settings:

```bash
cp .env.example .env
```

Edit `.env`:

```env
NODE_ENV=development
PORT=5000
HOST=0.0.0.0
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
ADMIN_API_KEY=your-super-secret-admin-key-change-this-in-production
FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account",...}
```

### 3. Run the server

**Development mode (with auto-reload):**
```bash
npm run dev
```

**Production mode:**
```bash
npm start
```

The server will start on `http://localhost:5000`

For Android emulators use:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
```

For a physical Android device on the same Wi-Fi network, either reverse the port:

```bash
adb reverse tcp:5000 tcp:5000
```

or start the app with your computer's LAN IP. The backend now prints reachable LAN URLs on startup, for example:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.25:5000/api
```

If you want extra failover addresses, pass a comma-separated list:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.25:5000/api --dart-define=API_BASE_URL_FALLBACKS=http://10.0.2.2:5000/api,http://127.0.0.1:5000/api
```

For hosted environments, keep the Node server on Render or another stable host and provide the Firebase Admin secrets through environment variables.

## Deployment

This backend is prepared for hosted deployment in three ways:

- `render.yaml` in the repository root for Render.
- `backend/Dockerfile` for Docker-compatible hosts.
- Production config validation in `backend/config/env.js` so weak secrets fail fast.

### Required production environment variables

```env
NODE_ENV=production
HOST=0.0.0.0
PORT=5000
JWT_SECRET=<strong-random-secret>
ADMIN_API_KEY=<strong-random-secret>
TRUST_PROXY=1
FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account",...}
```

### Optional production environment variables

```env
CORS_ALLOWED_ORIGINS=https://your-web-app.example.com,https://your-admin.example.com
FIREBASE_SERVICE_ACCOUNT_PATH=/etc/secrets/firebase-service-account.json
APP_VERSION=1.0.0
RELEASE_ID=deploy-001
REQUEST_BODY_LIMIT=25mb
KEEP_ALIVE_TIMEOUT_MS=65000
HEADERS_TIMEOUT_MS=66000
REQUEST_TIMEOUT_MS=30000
```

### Render

1. Push the repository to GitHub.
2. Create a new Render Blueprint or Web Service from the repo.
3. Use the generated `render.yaml`.
4. Set `FIREBASE_SERVICE_ACCOUNT_JSON` or mount a service-account file and set `FIREBASE_SERVICE_ACCOUNT_PATH`.
5. Set `CORS_ALLOWED_ORIGINS` only if you will serve browser clients.
6. Verify `https://<your-domain>/api/health` after deploy.

### Railway

1. Create a Railway project from the repo.
2. Set the root directory to `backend`.
3. Use either the included `Dockerfile` or the commands `npm ci` and `npm start`.
4. Add the production environment variables listed above.
5. Verify `/api/health` after deploy.

### Docker

From the repository root:

```bash
docker build -t mymedicine-backend ./backend
docker run --env-file ./backend/.env -p 5000:5000 mymedicine-backend
```

For production, do not use the local `.env`; provide hosted values for `JWT_SECRET`, `ADMIN_API_KEY`, and Firebase Admin.

### VPS or Render

Recommended production path:

1. Enable Firestore in your Firebase project.
2. Create a Firebase Admin service account with Firestore access.
3. Provision Render or a small Ubuntu VPS.
4. Point your DNS `api.<your-domain>` record to the deployed backend.
5. If using a VPS, copy the repository to the server and run:

```bash
sudo bash backend/deploy/bootstrap_ubuntu.sh
```

7. Copy `backend/.env.production.example` to `backend/.env.production` and fill in real values, especially:

```env
JWT_SECRET=...
ADMIN_API_KEY=...
FIREBASE_SERVICE_ACCOUNT_JSON=...
```

7. Deploy the backend:

```bash
cd backend
chmod +x deploy/deploy_vps.sh
./deploy/deploy_vps.sh
```

8. Install the Nginx site:

```bash
sudo bash backend/deploy/install_nginx_site.sh api.<your-domain>
```

9. Add TLS with Let's Encrypt:

```bash
sudo certbot --nginx -d api.<your-domain>
```

10. Verify:

```bash
curl http://127.0.0.1:5000/api/health
curl https://api.<your-domain>/api/health
```

The Compose file binds the backend to `127.0.0.1:5000`, so it is intended to sit behind Nginx on the VPS.

## API Endpoints

### Authentication (`/api/auth`)

#### Register User
```
POST /api/auth/register
Content-Type: application/json

{
  "username": "ahmed123",
  "password": "password123",
  "name": "Ahmed Ali",
  "userType": "patient"  // or "caregiver"
}

Response (201):
{
  "success": true,
  "userId": "507f1f77bcf86cd799439011",
  "username": "ahmed123",
  "name": "Ahmed Ali",
  "userType": "patient",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### Login
```
POST /api/auth/login
Content-Type: application/json

{
  "username": "ahmed123",
  "password": "password123"
}

Response (200):
{
  "success": true,
  "userId": "507f1f77bcf86cd799439011",
  "username": "ahmed123",
  "name": "Ahmed Ali",
  "userType": "patient",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### Logout
```
POST /api/auth/logout
Authorization: Bearer <token>

Response (200):
{
  "success": true,
  "message": "Logged out successfully"
}
```

### Caregiver Management (`/api/caregiver`)

All caregiver endpoints require authentication with `Authorization: Bearer <token>` header.

#### Generate Invitation Code
```
POST /api/caregiver/generate-invitation
Authorization: Bearer <token>
Content-Type: application/json

{
  "username": "ahmed123"
}

Response (201):
{
  "success": true,
  "invitationCode": "ABC123",
  "expiresAt": "2024-03-07T10:30:00Z"
}
```

#### Get Pending Invitations
```
GET /api/caregiver/invitations/caregiver_username
Authorization: Bearer <token>

Response (200):
{
  "success": true,
  "invitations": [
    {
      "_id": "507f1f77bcf86cd799439011",
      "invitationCode": "ABC123",
      "patientName": "Ahmed Ali",
      "patientUsername": "ahmed123",
      "status": "pending",
      "createdAt": "2024-03-06T10:30:00Z",
      "expiresAt": "2024-03-07T10:30:00Z"
    }
  ]
}
```

#### Accept Invitation
```
POST /api/caregiver/accept-invitation
Authorization: Bearer <token>
Content-Type: application/json

{
  "invitationCode": "ABC123",
  "caregiverUsername": "caregiver_user"
}

Response (200):
{
  "success": true,
  "message": "Invitation accepted and linked successfully",
  "patientName": "Ahmed Ali"
}
```

#### Reject Invitation
```
POST /api/caregiver/reject-invitation
Authorization: Bearer <token>
Content-Type: application/json

{
  "invitationCode": "ABC123"
}

Response (200):
{
  "success": true,
  "message": "Invitation rejected"
}
```

#### Get Linked Patients
```
GET /api/caregiver/patients/caregiver_username
Authorization: Bearer <token>

Response (200):
{
  "success": true,
  "patients": [
    {
      "_id": "507f1f77bcf86cd799439011",
      "name": "Ahmed Ali",
      "username": "ahmed123",
      "userType": "patient"
    }
  ]
}
```

#### Get Linked Caregiver
```
GET /api/caregiver/caregiver/patient_username
Authorization: Bearer <token>

Response (200):
{
  "success": true,
  "caregiver": {
    "_id": "507f1f77bcf86cd799439012",
    "name": "Sarah Nurse",
    "username": "sarah_nurse",
    "userType": "caregiver"
  }
}
```

#### Unlink Caregiver
```
POST /api/caregiver/unlink
Authorization: Bearer <token>
Content-Type: application/json

{
  "patientUsername": "ahmed123",
  "caregiverUsername": "sarah_nurse"
}

Response (200):
{
  "success": true,
  "message": "Caregiver unlinked successfully"
}
```

#### Notify Missed Doses
```
POST /api/caregiver/notify-missed-dose
Authorization: Bearer <token>
Content-Type: application/json

{
  "patientUsername": "ahmed123",
  "consecutiveMissed": 2,
  "medicationName": "Aspirin"
}

Response (200):
{
  "success": true,
  "message": "Missed dose notification sent",
  "caregiverNotified": true
}
```

## Database Schema

### User Collection

```javascript
{
  _id: ObjectId,
  username: String (unique, lowercase),
  password: String (hashed),
  name: String,
  userType: "patient" | "caregiver",
  caregiverId: ObjectId (null for patients without caregiver),
  patientIds: [ObjectId] (array of linked patient IDs),
  fcmToken: String (for push notifications),
  createdAt: Date,
  updatedAt: Date
}
```

### LinkInvitation Collection

```javascript
{
  _id: ObjectId,
  invitationCode: String (6 characters, unique),
  patientId: ObjectId,
  patientUsername: String,
  patientName: String,
  status: "pending" | "accepted" | "expired",
  createdAt: Date (auto-expires after 24 hours via TTL index),
  expiresAt: Date
}
```

## Error Handling

All endpoints return appropriate HTTP status codes:

- `200`: OK - Request successful
- `201`: Created - Resource created successfully
- `400`: Bad Request - Invalid request data
- `401`: Unauthorized - Missing or invalid token
- `404`: Not Found - Resource not found
- `500`: Internal Server Error - Server error

Error response format:

```json
{
  "message": "Error description"
}
```

## Security Considerations

1. **JWT Secret**: Change `JWT_SECRET` in `.env` to a strong, random string in production
2. **CORS**: Configure CORS origins according to your Flutter app's domain
3. **Password Security**: Passwords are hashed with bcrypt (10 rounds)
4. **Token Expiration**: JWT tokens expire after 30 days
5. **Invitation Codes**: Auto-expire after 24 hours based on Firestore timestamp checks

## Deployment

### Heroku

```bash
heroku create your-app-name
heroku config:set FIREBASE_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
heroku config:set JWT_SECRET=your-secret
git push heroku main
```

### AWS / Google Cloud / DigitalOcean

1. Set up Node.js environment
2. Configure Firebase Admin credentials and Firestore
3. Set environment variables
4. Deploy using your platform's deployment method

### Docker

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 5000
CMD ["npm", "start"]
```

## Testing

To test endpoints using cURL:

```bash
# Register
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"123456","name":"Test User","userType":"patient"}'

# Login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"123456"}'

# Generate Invitation (replace TOKEN with actual JWT token)
curl -X POST http://localhost:5000/api/caregiver/generate-invitation \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"test"}'
```

## Troubleshooting

**Firebase Admin / Firestore Error**
- Ensure `FIREBASE_SERVICE_ACCOUNT_JSON` or `FIREBASE_SERVICE_ACCOUNT_PATH` is set
- Confirm the service account has Firestore access in the target Firebase project
- Verify Firestore is enabled for the project

**JWT Token Errors**
- Ensure token is included in `Authorization: Bearer <token>` header
- Check token hasn't expired (30 days)
- Verify JWT_SECRET matches on server

**CORS Errors**
- Update `cors()` middleware in `server.js` to allow your Flutter app's domain
- For development, you can use `cors()` without restrictions

## Contributing

1. Create a feature branch: `git checkout -b feature/feature-name`
2. Commit changes: `git commit -am 'Add feature'`
3. Push to branch: `git push origin feature/feature-name`
4. Submit a pull request

## License

MIT License - see LICENSE file for details
