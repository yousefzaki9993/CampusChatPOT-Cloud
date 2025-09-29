#!/bin/bash

# Local Testing Script for Campus Chatbot
# This script helps you test the application locally before deploying

set -e

echo "🧪 Starting local testing for Campus Chatbot..."

# Step 1: Check if Docker is running
echo "🐳 Checking Docker status..."
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi
echo "✅ Docker is running"

# Step 2: Build the Docker image
echo "📦 Building Docker image..."
docker build -t campus-chatbot:local .

# Step 3: Run the container
echo "🚀 Starting container..."
docker run -d \
    --name campus-chatbot-test \
    -p 5000:5000 \
    -e FLASK_ENV=production \
    campus-chatbot:local

# Step 4: Wait for the application to start
echo "⏳ Waiting for application to start..."
sleep 30

# Step 5: Test the application
echo "🧪 Testing application..."

# Test health endpoint
if curl -f http://localhost:5000/ > /dev/null 2>&1; then
    echo "✅ Application is responding"
else
    echo "❌ Application is not responding"
    docker logs campus-chatbot-test
    exit 1
fi

# Test API endpoint
if curl -f http://localhost:5000/api/faq-list > /dev/null 2>&1; then
    echo "✅ API is working"
else
    echo "❌ API is not working"
    docker logs campus-chatbot-test
    exit 1
fi

# Test chat endpoint
echo "💬 Testing chat functionality..."
response=$(curl -s -X POST http://localhost:5000/api/chat \
    -H "Content-Type: application/json" \
    -d '{"msg": "How can I register for a course?"}')

if echo "$response" | grep -q "answer"; then
    echo "✅ Chat functionality is working"
    echo "📝 Sample response: $response"
else
    echo "❌ Chat functionality is not working"
    echo "Response: $response"
    docker logs campus-chatbot-test
    exit 1
fi

echo "🎉 All tests passed! Your application is ready for deployment."
echo "🌐 Access your application at: http://localhost:5000"
echo "🛑 To stop the container: docker stop campus-chatbot-test"
echo "🗑️ To remove the container: docker rm campus-chatbot-test"
