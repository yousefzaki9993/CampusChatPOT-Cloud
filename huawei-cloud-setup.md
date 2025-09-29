# Huawei Cloud Deployment Guide

## Prerequisites

1. **Huawei Cloud Account**: Sign up at [Huawei Cloud](https://www.huaweicloud.com/)
2. **Huawei Cloud CLI**: Install and configure the Huawei Cloud CLI
3. **Docker**: Install Docker on your local machine
4. **kubectl**: Install Kubernetes command-line tool

## Step 1: Install Huawei Cloud CLI

### Windows
```bash
# Download and install from Huawei Cloud website
# Or use PowerShell:
Invoke-WebRequest -Uri "https://cli.huaweicloud.com/cli/latest/huaweicloud-cli-windows-amd64.zip" -OutFile "huaweicloud-cli.zip"
Expand-Archive -Path "huaweicloud-cli.zip" -DestinationPath "C:\huaweicloud-cli"
```

### Linux/macOS
```bash
curl -sSL https://cli.huaweicloud.com/install.sh | bash
```

## Step 2: Configure Huawei Cloud CLI

```bash
# Login to Huawei Cloud
huaweicloud configure

# Enter your credentials:
# Access Key ID: [Your Access Key]
# Secret Access Key: [Your Secret Key]
# Region: ap-southeast-1 (or your preferred region)
# Output format: json
```

## Step 3: Create Container Registry Namespace

1. Go to Huawei Cloud Console
2. Navigate to **Container Registry Service (SWR)**
3. Create a new namespace (e.g., "campus-chatbot")
4. Note down your namespace name

## Step 4: Create Kubernetes Cluster (CCE)

1. Go to **Cloud Container Engine (CCE)**
2. Create a new cluster:
   - **Cluster Type**: Virtual Machine
   - **Region**: ap-southeast-1
   - **Node Flavor**: s6.large.2 (2 vCPUs, 4GB RAM)
   - **Node Count**: 2
   - **Network**: Use default VPC and subnet

## Step 5: Configure kubectl

```bash
# Get cluster credentials
huaweicloud cce cluster get-credentials --cluster-name your-cluster-name

# Verify connection
kubectl get nodes
```

## Step 6: Set Environment Variables

```bash
# Set your credentials
export HUAWEI_CLOUD_USERNAME="your-username"
export HUAWEI_CLOUD_PASSWORD="your-password"

# Update the namespace in deploy-huawei.sh
# Replace "your-namespace" with your actual namespace
```

## Step 7: Deploy the Application

```bash
# Make the script executable
chmod +x deploy-huawei.sh

# Run the deployment
./deploy-huawei.sh
```

## Step 8: Access Your Application

After deployment, get the LoadBalancer IP:

```bash
kubectl get services campus-chatbot-service
```

Open your browser and navigate to: `http://[LOADBALANCER_IP]`

## Monitoring and Management

### Check Application Status
```bash
# Check pods
kubectl get pods -l app=campus-chatbot

# Check logs
kubectl logs -l app=campus-chatbot

# Check service
kubectl get services campus-chatbot-service
```

### Scale Application
```bash
# Scale to 3 replicas
kubectl scale deployment campus-chatbot --replicas=3
```

### Update Application
```bash
# Build new image
docker build -t campus-chatbot:v2 .

# Tag and push
docker tag campus-chatbot:v2 swr.ap-southeast-1.myhuaweicloud.com/your-namespace/campus-chatbot:v2
docker push swr.ap-southeast-1.myhuaweicloud.com/your-namespace/campus-chatbot:v2

# Update deployment
kubectl set image deployment/campus-chatbot campus-chatbot=swr.ap-southeast-1.myhuaweicloud.com/your-namespace/campus-chatbot:v2
```

## Troubleshooting

### Common Issues

1. **Image Pull Errors**: Check namespace and credentials
2. **Pod CrashLoopBackOff**: Check logs with `kubectl logs [pod-name]`
3. **Service Not Accessible**: Check LoadBalancer status and security groups

### Useful Commands

```bash
# Describe pod for detailed info
kubectl describe pod [pod-name]

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Port forward for local testing
kubectl port-forward service/campus-chatbot-service 8080:80
```

## Cost Optimization

1. **Use Spot Instances**: For non-production environments
2. **Right-size Resources**: Adjust CPU/memory requests based on usage
3. **Auto-scaling**: Configure HPA for automatic scaling
4. **Scheduled Scaling**: Scale down during off-hours

## Security Best Practices

1. **Use Secrets**: Store sensitive data in Kubernetes secrets
2. **Network Policies**: Implement network segmentation
3. **RBAC**: Configure proper role-based access control
4. **Image Security**: Scan images for vulnerabilities
