# Setup Instructions

This document provides step-by-step instructions to set up and run the distributed image classifier service.

## Prerequisites

- Docker and Docker Compose
- Kubernetes cluster (Minikube, kind, or cloud provider like GKE, EKS, AKS)
- kubectl configured to connect to your cluster
- Git

## Local Development Setup

### 1. Clone the repository

```bash
git clone <repository-url>
cd distributed-image-classifier
```

### 2. Start the local development environment

```bash
docker-compose up --build
```

This will start:
- The image classifier API at http://localhost:8000
- Prometheus at http://localhost:9090
- Grafana at http://localhost:3000 (admin/admin)

### 3. Verify the setup

Access the API documentation at http://localhost:8000/docs to explore the endpoints.

## Kubernetes Deployment

### 1. Set up a Kubernetes cluster

If you don't have a cluster, you can create one using Minikube:

```bash
# Install Minikube
brew install minikube # on macOS
# or using other methods for your OS

# Start a Minikube cluster
minikube start --cpus=4 --memory=4g

# Enable the ingress addon
minikube addons enable ingress
```

### 2. Deploy the application

Use the provided deployment script:

```bash
# Set environment variables (optional)
export DOCKER_REGISTRY=your-registry # default is localhost
export TAG=v1.0 # default is latest

# Run the deployment script
./scripts/deploy.sh
```

### 3. Access the application

```bash
# Get the service URL
kubectl get ingress -n image-classifier

# If using Minikube, you can create a tunnel
minikube service image-classifier -n image-classifier --url
```

## Load Testing

### 1. Prepare test images

Add some test images to the `load-testing/test-images` directory:

```bash
mkdir -p load-testing/test-images
# Copy some test images into this directory
```

### 2. Run Locust

```bash
cd load-testing/locust
pip install -r requirements.txt
locust -f locustfile.py --host=http://localhost:8000
```

Then access the Locust web interface at http://localhost:8089 to start a test.

## Monitoring

### 1. Access Grafana

Open http://localhost:3000 (or the Kubernetes service URL) and log in with admin/admin.

### 2. View dashboards

The Image Classifier Dashboard will be available in Grafana.

### 3. View Prometheus metrics

Access Prometheus at http://localhost:9090 (or the Kubernetes service URL) to query raw metrics.

## Troubleshooting

### Common issues

1. **Pod fails to start**
   ```bash
   kubectl describe pod -n image-classifier
   kubectl logs -n image-classifier <pod-name>
   ```

2. **Service is not accessible**
   ```bash
   kubectl get svc -n image-classifier
   kubectl get ingress -n image-classifier
   ```

3. **High resource usage**
   ```bash
   kubectl top pods -n image-classifier
   ```

### Restarting the application

```bash
kubectl rollout restart deployment/image-classifier -n image-classifier
```

### Clean up

To remove the application and associated resources:

```bash
./scripts/cleanup.sh
```

## Prometheus RBAC

### 1. Create a dedicated ServiceAccount for Prometheus

```bash
kubectl create serviceaccount prometheus -n image-classifier
```

### 2. Create a ClusterRole for Prometheus

```bash
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroups: [""]
  resources: ["nodes", "nodes/proxy", "services", "endpoints", "pods"]
  verbs: ["get", "list", "watch"]
EOF
```

### 3. Bind the ClusterRole to the ServiceAccount

```bash
kubectl create clusterrolebinding prometheus --clusterrole=prometheus --serviceaccount=image-classifier:prometheus
```

### 4. Update the Prometheus deployment to use this ServiceAccount

```bash
kubectl patch deployment prometheus -n image-classifier -p '{"spec":{"template":{"spec":{"serviceAccountName":"prometheus"}}}}'
```
