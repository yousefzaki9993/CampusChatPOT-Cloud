# Windows Setup Guide for Campus Chatbot

## Prerequisites for Windows

### 1. Install Docker Desktop
1. Download Docker Desktop from [docker.com](https://www.docker.com/products/docker-desktop/)
2. Install and start Docker Desktop
3. Verify installation: Open PowerShell and run `docker --version`

### 2. Install kubectl
```powershell
# Download kubectl
Invoke-WebRequest -Uri "https://dl.k8s.io/release/v1.28.0/bin/windows/amd64/kubectl.exe" -OutFile "kubectl.exe"
# Move to a directory in your PATH (e.g., C:\Windows\System32)
Move-Item kubectl.exe C:\Windows\System32\
# Verify installation
kubectl version --client
```

### 3. Install Huawei Cloud CLI
```powershell
# Download and install
Invoke-WebRequest -Uri "https://cli.huaweicloud.com/cli/latest/huaweicloud-cli-windows-amd64.zip" -OutFile "huaweicloud-cli.zip"
Expand-Archive -Path "huaweicloud-cli.zip" -DestinationPath "C:\huaweicloud-cli"
# Add to PATH
$env:PATH += ";C:\huaweicloud-cli"
# Verify installation
huaweicloud version
```

## Quick Start Commands (Windows)

### 1. Test Locally
```powershell
# Run the PowerShell test script
.\local-test.ps1
```

### 2. Deploy to Huawei Cloud
```powershell
# Set environment variables
$env:HUAWEI_CLOUD_USERNAME = "your-username"
$env:HUAWEI_CLOUD_PASSWORD = "your-password"

# Run deployment (replace with your actual namespace)
.\deploy-huawei.ps1 -Namespace "your-actual-namespace"
```

### 3. Alternative: Use Docker Compose
```powershell
# Start with Docker Compose
docker-compose up -d

# Check logs
docker-compose logs -f

# Stop
docker-compose down
```

## Troubleshooting Windows Issues

### Docker Issues
```powershell
# Check Docker status
docker info

# Restart Docker Desktop if needed
# (Use Docker Desktop GUI or restart Windows service)
```

### PowerShell Execution Policy
If you get execution policy errors:
```powershell
# Allow script execution (run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or run individual commands
PowerShell -ExecutionPolicy Bypass -File .\local-test.ps1
```

### Port Already in Use
```powershell
# Check what's using port 5000
netstat -ano | findstr :5000

# Kill the process (replace PID with actual process ID)
taskkill /PID <PID> /F

# Or use a different port
docker run -p 8080:5000 campus-chatbot:local
```

### Container Issues
```powershell
# Check container logs
docker logs campus-chatbot-test

# Remove problematic container
docker rm -f campus-chatbot-test

# Clean up Docker
docker system prune -a
```

## Manual Testing Steps

If the automated script fails, you can test manually:

### 1. Build and Run
```powershell
# Build image
docker build -t campus-chatbot:local .

# Run container
docker run -d --name campus-chatbot-test -p 5000:5000 campus-chatbot:local

# Check if running
docker ps
```

### 2. Test Endpoints
```powershell
# Test health endpoint
Invoke-WebRequest -Uri "http://localhost:5000/"

# Test API
Invoke-WebRequest -Uri "http://localhost:5000/api/faq-list"

# Test chat
$body = @{ msg = "How can I register for a course?" } | ConvertTo-Json
Invoke-WebRequest -Uri "http://localhost:5000/api/chat" -Method POST -Body $body -ContentType "application/json"
```

### 3. Clean Up
```powershell
# Stop and remove container
docker stop campus-chatbot-test
docker rm campus-chatbot-test
```

## File Structure
```
CampusChatPOT-Cloud/
├── app.py                          # Main Flask application
├── build_index.py                  # BERT index builder
├── requirements.txt                # Python dependencies
├── Dockerfile                      # Docker configuration
├── docker-compose.yml              # Docker Compose setup
├── local-test.ps1                  # Windows test script
├── deploy-huawei.ps1               # Windows deployment script
├── k8s-deployment.yaml             # Kubernetes configuration
├── huawei-cloud-setup.md           # Setup documentation
├── windows-setup.md                # This file
└── data/
    ├── faqs.json                   # FAQ data
    ├── bert_embeddings.pkl         # Generated embeddings
    └── bert_index.pkl              # Generated index
```

## Next Steps

1. **Test locally** with `.\local-test.ps1`
2. **Set up Huawei Cloud** following `huawei-cloud-setup.md`
3. **Deploy** with `.\deploy-huawei.ps1 -Namespace "your-namespace"`
4. **Access** your chatbot via the LoadBalancer IP

## Support

If you encounter issues:
1. Check Docker Desktop is running
2. Verify all prerequisites are installed
3. Check container logs: `docker logs campus-chatbot-test`
4. Ensure ports are not in use
5. Try running commands manually to isolate the issue
