#!/bin/bash

# Huawei Cloud Deployment Script for Campus Chatbot
# Make sure you have Huawei Cloud CLI installed and configured

set -e

# Configuration
PROJECT_NAME="campus-chatbot"
REGION="ap-southeast-1"  # Singapore region
IMAGE_NAME="campus-chatbot"
TAG="latest"
CONTAINER_REGISTRY="swr.${REGION}.myhuaweicloud.com"
NAMESPACE="your-namespace"  # Replace with your namespace

echo "🚀 Starting Huawei Cloud deployment for Campus Chatbot..."

# Step 1: Build Docker image
echo "📦 Building Docker image..."
docker build -t ${IMAGE_NAME}:${TAG} .

# Step 2: Tag image for Huawei Cloud Container Registry
echo "🏷️ Tagging image for Huawei Cloud..."
docker tag ${IMAGE_NAME}:${TAG} ${CONTAINER_REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${TAG}

# Step 3: Login to Huawei Cloud Container Registry
echo "🔐 Logging in to Huawei Cloud Container Registry..."
docker login ${CONTAINER_REGISTRY} -u ${HUAWEI_CLOUD_USERNAME} -p ${HUAWEI_CLOUD_PASSWORD}

# Step 4: Push image to registry
echo "⬆️ Pushing image to registry..."
docker push ${CONTAINER_REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${TAG}

# Step 5: Create deployment YAML
echo "📝 Creating deployment configuration..."
cat > k8s-deployment.yaml << EOF
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
        image: ${CONTAINER_REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${TAG}
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
EOF

# Step 6: Deploy to Kubernetes
echo "🚀 Deploying to Kubernetes..."
kubectl apply -f k8s-deployment.yaml

# Step 7: Wait for deployment
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/campus-chatbot

# Step 8: Get service information
echo "📊 Getting service information..."
kubectl get services campus-chatbot-service

echo "✅ Deployment completed!"
echo "🌐 Your chatbot should be accessible via the LoadBalancer IP shown above"
echo "📋 To check logs: kubectl logs -l app=campus-chatbot"
echo "🔄 To scale: kubectl scale deployment campus-chatbot --replicas=3"
