# MyMedicine Admin API Testing Script
# This script demonstrates how to use the admin API endpoints

# Set your admin key (from backend/.env file)
$adminKey = "admin-secret-key-change-this-12345"
$baseUrl = "http://localhost:5000/api"
$headers = @{
    "x-admin-key" = $adminKey
    "Content-Type" = "application/json"
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MyMedicine Admin API Testing" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to display JSON nicely
function Show-Result {
    param($response)
    try {
        $json = $response.Content | ConvertFrom-Json
        $json | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor Green
    } catch {
        Write-Host $response.Content -ForegroundColor Yellow
    }
}

# 1. Get Statistics
Write-Host "1. Getting Database Statistics..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/admin/stats" -Method GET -Headers $headers -ErrorAction Stop
    Show-Result $response
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
Write-Host ""

# 2. Get All Users
Write-Host "2. Getting All Users..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/admin/users" -Method GET -Headers $headers -ErrorAction Stop
    Show-Result $response
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
Write-Host ""

# 3. Search for a user (if you have any)
Write-Host "3. Search for User (example: 'test')..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/admin/search?q=test" -Method GET -Headers $headers -ErrorAction Stop
    Show-Result $response
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
Write-Host ""

# 4. Get All Invitations
Write-Host "4. Getting All Invitations..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/admin/invitations" -Method GET -Headers $headers -ErrorAction Stop
    Show-Result $response
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
Write-Host ""

# 5. Get Activity (last 7 days)
Write-Host "5. Getting Recent Activity..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/admin/activity?days=7" -Method GET -Headers $headers -ErrorAction Stop
    Show-Result $response
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Available Admin Endpoints:" -ForegroundColor Cyan
Write-Host "- GET  /api/admin/stats" -ForegroundColor White
Write-Host "- GET  /api/admin/users" -ForegroundColor White
Write-Host "- GET  /api/admin/user/:username" -ForegroundColor White
Write-Host "- GET  /api/admin/search?q=query" -ForegroundColor White
Write-Host "- GET  /api/admin/invitations" -ForegroundColor White
Write-Host "- GET  /api/admin/activity?days=7" -ForegroundColor White
Write-Host "- DELETE /api/admin/user/:username" -ForegroundColor White
Write-Host "- PATCH /api/admin/user/:username/type" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Example: Get specific user" -ForegroundColor Yellow
Write-Host 'Invoke-WebRequest -Uri "http://localhost:5000/api/admin/user/testuser123" -Method GET -Headers @{"x-admin-key"="$adminKey"}' -ForegroundColor Gray
Write-Host ""

Write-Host "Example: Delete user" -ForegroundColor Yellow
Write-Host 'Invoke-WebRequest -Uri "http://localhost:5000/api/admin/user/testuser123" -Method DELETE -Headers @{"x-admin-key"="$adminKey"}' -ForegroundColor Gray
Write-Host ""

Write-Host "Example: Reset user password" -ForegroundColor Yellow
Write-Host '$body = @{ username = "testuser123"; newPassword = "newpassword123" } | ConvertTo-Json' -ForegroundColor Gray
Write-Host 'Invoke-WebRequest -Uri "http://localhost:5000/api/auth/reset-password" -Method POST -Headers @{"Content-Type"="application/json"} -Body $body' -ForegroundColor Gray
