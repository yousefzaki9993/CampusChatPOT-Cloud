# Huawei Cloud Deployment Script for Campus Chatbot (Windows PowerShell)
# Make sure you have Huawei Cloud CLI installed and configured

param(
    [string]$Namespace = "your-namespace",
    [string]$Region = "ap-southeast-1",
    [string]$Username = $env:HUAWEI_CLOUD_USERNAME,
    [string]$Password = $env:HUAWEI_CLOUD_PASSWORD
)

# Configuration
$ProjectName = "campus-chatbot"
$ImageName = "campus-chatbot"
$Tag = "latest"
$ContainerRegistry = "swr.$Region.myhuaweicloud.com"

Write-Host "Starting Huawei Cloud deployment for Campus Chatbot..." -ForegroundColor Green

# Check if required parameters are provided
if (-not $Username -or -not $Password) {
    Write-Host "Please set HUAWEI_CLOUD_USERNAME and HUAWEI_CLOUD_PASSWORD environment variables" -ForegroundColor Red
    Write-Host "Or provide them as parameters: .\deploy-huawei.ps1 -Username 'your-username' -Password 'your-password'" -ForegroundColor Yellow
    exit 1
}

if ($Namespace -eq "your-namespace") {
    Write-Host "Please provide your actual namespace" -ForegroundColor Red
    Write-Host "Usage: .\deploy-huawei.ps1 -Namespace 'your-actual-namespace'" -ForegroundColor Yellow
    exit 1
}

# Step 1: Build Docker image
Write-Host "Building Docker image..." -ForegroundColor Yellow
docker build -t "${ImageName}:${Tag}" .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker build failed" -ForegroundColor Red
    exit 1
}

# Step 2: Tag image for Huawei Cloud Container Registry
Write-Host "Tagging image for Huawei Cloud..." -ForegroundColor Yellow
docker tag "${ImageName}:${Tag}" "${ContainerRegistry}/${Namespace}/${ImageName}:${Tag}"

# Step 3: Login to Huawei Cloud Container Registry
Write-Host "Logging in to Huawei Cloud Container Registry..." -ForegroundColor Yellow
echo $Password | docker login $ContainerRegistry -u $Username --password-stdin

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to login to container registry" -ForegroundColor Red
    exit 1
}

# Step 4: Push image to registry
Write-Host "Pushing image to registry..." -ForegroundColor Yellow
docker push "${ContainerRegistry}/${Namespace}/${ImageName}:${Tag}"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to push image to registry" -ForegroundColor Red
    exit 1
}

# Step 5: Create deployment YAML
Write-Host "Creating deployment configuration..." -ForegroundColor Yellow
$DeploymentYaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: campus-chatbot
  labels:
    app: campus-chatbot
spec:
  replicas: 2
  selector:
    matchLabels:
      app: campus-chatbot
  template:
    metadata:
      labels:
        app: campus-chatbot
    spec:
      containers:
      - name: campus-chatbot
        image: ${ContainerRegistry}/${Namespace}/${ImageName}:${Tag}
        ports:
        - containerPort: 5000
        env:
        - name: FLASK_ENV
          value: "production"
        - name: PYTHONUNBUFFERED
          value: "1"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /
            port: 5000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: campus-chatbot-service
spec:
  selector:
    app: campus-chatbot
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5000
  type: LoadBalancer
"@

$DeploymentYaml | Out-File -FilePath "k8s-deployment.yaml" -Encoding UTF8

# Step 6: Deploy to Kubernetes
Write-Host "Deploying to Kubernetes..." -ForegroundColor Yellow
kubectl apply -f k8s-deployment.yaml

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to deploy to Kubernetes" -ForegroundColor Red
    exit 1
}

# Step 7: Wait for deployment
Write-Host "Waiting for deployment to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=available --timeout=300s deployment/campus-chatbot

if ($LASTEXITCODE -ne 0) {
    Write-Host "Deployment failed or timed out" -ForegroundColor Red
    Write-Host "Checking pod status:" -ForegroundColor Yellow
    kubectl get pods -l app=campus-chatbot
    exit 1
}

# Step 8: Get service information
Write-Host "Getting service information..." -ForegroundColor Yellow
kubectl get services campus-chatbot-service

Write-Host "Deployment completed!" -ForegroundColor Green
Write-Host "Your chatbot should be accessible via the LoadBalancer IP shown above" -ForegroundColor Cyan
Write-Host "To check logs: kubectl logs -l app=campus-chatbot" -ForegroundColor Yellow
Write-Host "To scale: kubectl scale deployment campus-chatbot --replicas=3" -ForegroundColor Yellow