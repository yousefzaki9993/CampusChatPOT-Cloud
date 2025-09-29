# Local Testing Script for Campus Chatbot (Windows PowerShell)
# This script helps you test the application locally before deploying

Write-Host "Starting local testing for Campus Chatbot..." -ForegroundColor Green

# Step 1: Check if Docker is running
Write-Host "Checking Docker status..." -ForegroundColor Yellow
try {
    docker info | Out-Null
    Write-Host "Docker is running" -ForegroundColor Green
} catch {
    Write-Host "Docker is not running. Please start Docker Desktop and try again." -ForegroundColor Red
    exit 1
}

# Step 2: Build the Docker image
Write-Host "Building Docker image..." -ForegroundColor Yellow
docker build -t campus-chatbot:local .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker build failed" -ForegroundColor Red
    exit 1
}

# Step 3: Stop and remove any existing container
Write-Host "Cleaning up existing containers..." -ForegroundColor Yellow
docker stop campus-chatbot-test 2>$null
docker rm campus-chatbot-test 2>$null

# Step 4: Run the container
Write-Host "Starting container..." -ForegroundColor Yellow
docker run -d --name campus-chatbot-test -p 5000:5000 -e FLASK_ENV=production campus-chatbot:local

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to start container" -ForegroundColor Red
    exit 1
}

# Step 5: Wait for the application to start
Write-Host "Waiting for application to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Step 6: Test the application
Write-Host "Testing application..." -ForegroundColor Yellow

# Test health endpoint
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000/" -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "Application is responding" -ForegroundColor Green
    } else {
        throw "Non-200 status code"
    }
} catch {
    Write-Host "Application is not responding" -ForegroundColor Red
    Write-Host "Container logs:" -ForegroundColor Yellow
    docker logs campus-chatbot-test
    exit 1
}

# Test API endpoint
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000/api/faq-list" -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "API is working" -ForegroundColor Green
    } else {
        throw "Non-200 status code"
    }
} catch {
    Write-Host "API is not working" -ForegroundColor Red
    Write-Host "Container logs:" -ForegroundColor Yellow
    docker logs campus-chatbot-test
    exit 1
}

# Test chat endpoint
Write-Host "Testing chat functionality..." -ForegroundColor Yellow
try {
    $body = @{
        msg = "How can I register for a course?"
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "http://localhost:5000/api/chat" -Method POST -Body $body -ContentType "application/json" -UseBasicParsing -TimeoutSec 10

    if ($response.StatusCode -eq 200) {
        $responseData = $response.Content | ConvertFrom-Json
        if ($responseData.answer) {
            Write-Host "Chat functionality is working" -ForegroundColor Green
            Write-Host "Sample response: $($responseData.answer)" -ForegroundColor Cyan
        } else {
            throw "No answer in response"
        }
    } else {
        throw "Non-200 status code"
    }
} catch {
    Write-Host "Chat functionality is not working" -ForegroundColor Red
    Write-Host "Response: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Container logs:" -ForegroundColor Yellow
    docker logs campus-chatbot-test
    exit 1
}

Write-Host "All tests passed! Your application is ready for deployment." -ForegroundColor Green
Write-Host "Access your application at: http://localhost:5000" -ForegroundColor Cyan
Write-Host "To stop the container: docker stop campus-chatbot-test" -ForegroundColor Yellow
Write-Host "To remove the container: docker rm campus-chatbot-test" -ForegroundColor Yellow