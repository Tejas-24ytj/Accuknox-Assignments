# Wisecow Application - EKS Deployment Guide

#Google Drive Link Demonstration of Task -
https://drive.google.com/file/d/1_91UGPSYRuEAHUn8Kl50goLgl6KNusKW/view?usp=sharing

## Overview
This guide provides step-by-step instructions to deploy the Wisecow application on Amazon EKS with HTTPS using Let's Encrypt certificates and AWS Load Balancer.

## Prerequisites
- AWS CLI configured with appropriate permissions
- kubectl installed
- eksctl installed
- Docker installed
- A registered domain name
- Domain DNS managed by Route53 (recommended)

## Step 1: Create EKS Cluster

```bash
# Create EKS cluster
eksctl create cluster \
  --name wisecow-cluster \
  --region us-west-2 \
  --nodegroup-name wisecow-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed

# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name wisecow-cluster
```

## Step 2: Install AWS Load Balancer Controller

```bash
# Create IAM OIDC provider
eksctl utils associate-iam-oidc-provider --region=us-west-2 --cluster=wisecow-cluster --approve

# Download IAM policy
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json

# Create IAM policy
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# Create IAM service account
eksctl create iamserviceaccount \
  --cluster=wisecow-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::ACCOUNT-ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# Install AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=wisecow-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

## Step 3: Install cert-manager

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager to be ready
kubectl wait --namespace cert-manager --for=condition=ready pod --selector=app=cert-manager --timeout=90s
```

## Step 4: Build and Push Docker Image

```bash
# Build Docker image
docker build -t wisecow:latest .

# Tag for ECR (replace ACCOUNT-ID and REGION)
docker tag wisecow:latest ACCOUNT-ID.dkr.ecr.REGION.amazonaws.com/wisecow:latest

# Login to ECR
aws ecr get-login-password --region REGION | docker login --username AWS --password-stdin ACCOUNT-ID.dkr.ecr.REGION.amazonaws.com

# Create ECR repository
aws ecr create-repository --repository-name wisecow --region REGION

# Push image
docker push ACCOUNT-ID.dkr.ecr.REGION.amazonaws.com/wisecow:latest
```

## Step 5: Update Kubernetes Manifests

### Update deployment.yaml
```yaml
# Update image in k8s/deployment.yaml
image: ACCOUNT-ID.dkr.ecr.REGION.amazonaws.com/wisecow:latest
imagePullPolicy: Always
```

### Update cert-issuer.yaml
```yaml
# Update email in k8s/cert-issuer.yaml
email: your-email@domain.com
```

### Update ingress.yaml
```yaml
# Update host in k8s/ingress.yaml
- host: tejaslamkhade.xyz
```

## Step 6: Deploy Application

```bash
# Apply cert-manager issuer
kubectl apply -f k8s/cert-issuer.yaml

# Deploy application
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Wait for deployment
kubectl wait --for=condition=available --timeout=300s deployment/wisecow-deployment

# Apply ingress (this will create ALB)
kubectl apply -f k8s/ingress.yaml
```

## Step 7: Configure DNS

```bash
# Get ALB hostname
kubectl get ingress wisecow-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Create A record pointing tejaslamkhade.xyz to ALB hostname
# Or update your DNS provider to point to the ALB
```

## Step 8: Verify Deployment

```bash
# Check all resources
kubectl get all,ingress,certificate

# Check certificate status
kubectl describe certificate wisecow-tls

# Test application
curl https://tejaslamkhade.xyz
```

## Troubleshooting

### Check pod logs
```bash
kubectl logs -l app=wisecow
```

### Check ingress events
```bash
kubectl describe ingress wisecow-ingress
```

### Check certificate issues
```bash
kubectl describe certificate wisecow-tls
kubectl describe certificaterequest
```

### Check ALB controller logs
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

## Cleanup

```bash
# Delete application
kubectl delete -f k8s/

# Delete EKS cluster
eksctl delete cluster --name wisecow-cluster --region us-west-2
```

## Important Notes

1. **Replace placeholders:**
   - `ACCOUNT-ID`: Your AWS account ID
   - `REGION`: Your AWS region
   - `tejaslamkhade.xyz`: Your domain name
   - `your-email@domain.com`: Your email for Let's Encrypt

2. **Security Groups:** Ensure ALB security group allows HTTP (80) and HTTPS (443) traffic

3. **Domain Validation:** Let's Encrypt requires domain to be publicly accessible for HTTP-01 challenge

4. **Costs:** EKS cluster and ALB incur AWS charges

5. **SSL Certificate:** Let's Encrypt certificates auto-renew every 90 days
