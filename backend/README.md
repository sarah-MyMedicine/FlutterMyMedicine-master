# MyMedicine Backend API

Backend API server for the MyMedicine Flutter app, built with Node.js, Express.js, and MongoDB.

## Features

- User authentication with JWT (username/password)
- Patient and Caregiver account types
- Caregiver invitation system with time-limited codes
- Patient-Caregiver linking and unlinking
- Missed dose notifications
- MongoDB Atlas or local MongoDB support

## Prerequisites

- Node.js (v14 or higher)
- npm or yarn
- MongoDB (local or MongoDB Atlas)

## Installation

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
MONGO_URI=mongodb://localhost:27017/mymedicine
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
```

### 3. Start MongoDB

**Local MongoDB:**
```bash
mongod
```

**MongoDB Atlas (Cloud):**
- Update `MONGO_URI` in `.env` with your connection string:
```
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/mymedicine?retryWrites=true&w=majority
```

### 4. Run the server

**Development mode (with auto-reload):**
```bash
npm run dev
```

**Production mode:**
```bash
npm start
```

The server will start on `http://localhost:5000`

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
5. **Invitation Codes**: Auto-expire after 24 hours via MongoDB TTL index

## Deployment

### Heroku

```bash
heroku create your-app-name
heroku config:set MONGO_URI=your-mongodb-url
heroku config:set JWT_SECRET=your-secret
git push heroku main
```

### AWS / Google Cloud / DigitalOcean

1. Set up Node.js environment
2. Install MongoDB or use managed database service
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

**MongoDB Connection Error**
- Ensure MongoDB is running: `mongod`
- Check connection string in `.env`
- For MongoDB Atlas, verify IP whitelist includes your server

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
