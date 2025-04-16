#!/bin/bash

# Exit on error
set -e

# Configuration
NAMESPACE="image-classifier"
DOCKER_REGISTRY=${DOCKER_REGISTRY:-"localhost"}
IMAGE_NAME="image-classifier"
TAG=${TAG:-"latest"}
FULL_IMAGE_NAME="$DOCKER_REGISTRY/$IMAGE_NAME:$TAG"
SKIP_PUSH=${SKIP_PUSH:-"true"}
TIMEOUT=${TIMEOUT:-"180s"}
DEBUG=${DEBUG:-"true"}

echo "===== Deploying Image Classifier to Kubernetes ====="
echo "Namespace: $NAMESPACE"
echo "Image: $FULL_IMAGE_NAME"
echo "Skip push: $SKIP_PUSH"
echo "Timeout: $TIMEOUT"

# Check if running in Minikube
IS_MINIKUBE=false
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    IS_MINIKUBE=true
    echo "Detected Minikube environment"

    # Point shell to Minikube's Docker daemon
    echo "Using Minikube's Docker daemon..."
    eval $(minikube -p minikube docker-env)
    
    # Always skip push when using Minikube
    SKIP_PUSH="true"
    # Use 'latest' without registry prefix for Minikube
    FULL_IMAGE_NAME="$IMAGE_NAME:$TAG"
    echo "Updated image name for Minikube: $FULL_IMAGE_NAME"
fi

# Build Docker image
echo "Building Docker image..."
docker build -t $FULL_IMAGE_NAME .

# Push Docker image if not using local registry, not Minikube, and SKIP_PUSH is not true
if [ "$IS_MINIKUBE" = false ] && [ "$DOCKER_REGISTRY" != "localhost" ] && [ "$SKIP_PUSH" != "true" ]; then
    echo "Pushing Docker image to registry..."
    
    # Check if user is logged in to the registry
    if ! docker info | grep -q "Username"; then
        echo "You don't seem to be logged in to Docker Hub or your registry."
        echo "Please log in using 'docker login' before running this script,"
        echo "or set SKIP_PUSH=true to skip the push step."
        echo ""
        echo "Example: SKIP_PUSH=true ./scripts/deploy.sh"
        exit 1
    fi
    
    # Try to push the image
    if ! docker push $FULL_IMAGE_NAME; then
        echo "Failed to push image to $DOCKER_REGISTRY."
        echo "- Check if you have permission to push to this repository"
        echo "- Ensure the repository exists"
        echo "- You can set SKIP_PUSH=true to skip pushing and use a local image"
        exit 1
    fi
else
    echo "Skipping Docker image push (using Minikube, local image, or SKIP_PUSH is true)"
fi

# Create namespace if it doesn't exist
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    echo "Creating namespace: $NAMESPACE"
    kubectl create namespace $NAMESPACE
fi

# Apply Kubernetes manifests
echo "Applying Kubernetes manifests..."

# Change imagePullPolicy to Never when using Minikube
if [ "$IS_MINIKUBE" = true ]; then
    echo "Setting imagePullPolicy to Never for Minikube..."
    sed -i.bak 's/imagePullPolicy: IfNotPresent/imagePullPolicy: Never/g' kubernetes/deployment.yaml
fi

# Replace image placeholder in deployment.yaml
sed -i.bak "s|\${DOCKER_REGISTRY:-localhost}/image-classifier:latest|$FULL_IMAGE_NAME|g" kubernetes/deployment.yaml

# Apply ConfigMap first
kubectl apply -f kubernetes/configmap.yaml -n $NAMESPACE

# Apply other resources
kubectl apply -f kubernetes/deployment.yaml -n $NAMESPACE
kubectl apply -f kubernetes/service.yaml -n $NAMESPACE
kubectl apply -f kubernetes/ingress.yaml -n $NAMESPACE
kubectl apply -f kubernetes/hpa.yaml -n $NAMESPACE

# Restore original deployment.yaml
mv kubernetes/deployment.yaml.bak kubernetes/deployment.yaml &> /dev/null || true

# Deploy monitoring stack
echo "Deploying monitoring stack..."
# Apply RBAC permissions for Prometheus first
kubectl apply -f monitoring/prometheus/prometheus-rbac.yaml -n $NAMESPACE
# Apply Prometheus and Grafana configuration and deployments
kubectl apply -f monitoring/prometheus/prometheus-config.yaml -n $NAMESPACE
kubectl apply -f monitoring/prometheus/prometheus-deployment.yaml -n $NAMESPACE
kubectl apply -f monitoring/grafana/grafana-deployment.yaml -n $NAMESPACE

# Wait for deployment to be ready with timeout
echo "Waiting for deployment to be ready (timeout: $TIMEOUT)..."
if ! kubectl rollout status deployment/image-classifier -n $NAMESPACE --timeout=$TIMEOUT; then
    echo "Deployment did not complete in time. Checking pod status:"
    kubectl get pods -n $NAMESPACE
    echo ""
    echo "Checking logs from failed pods:"
    for pod in $(kubectl get pods -n $NAMESPACE -l app=image-classifier -o jsonpath='{.items[*].metadata.name}'); do
        echo "=== Logs from $pod ==="
        kubectl logs $pod -n $NAMESPACE || echo "Could not get logs"
        echo ""
        echo "=== Events for $pod ==="
        kubectl describe pod $pod -n $NAMESPACE | grep -A 15 Events:
        echo ""
        
        # Show more detailed information
        echo "=== Detailed pod description ==="
        kubectl describe pod $pod -n $NAMESPACE
    done
    echo "Deployment failed. You can retry with: ./scripts/deploy.sh"
    exit 1
fi

# Create dedicated service for metrics that Prometheus needs
echo "Creating dedicated 'api' service for Prometheus..."
kubectl apply -f api-service.yaml

# Update Prometheus configuration
echo "Updating Prometheus configuration..."
# The prometheus configuration is now maintained in the prometheus-config.yaml file
# and is applied during the monitoring stack deployment

# Restart Prometheus to apply changes
echo "Restarting Prometheus to apply changes..."
kubectl rollout restart deployment prometheus -n $NAMESPACE
echo "Waiting for Prometheus to restart..."
kubectl rollout status deployment prometheus -n $NAMESPACE --timeout=60s

echo "===== Deployment Completed ====="
echo "Access the service:"

# Get access information specific to the environment
if [ "$IS_MINIKUBE" = true ]; then
    MINIKUBE_IP=$(minikube ip)
    echo "- API: http://$MINIKUBE_IP/api/v1"
    echo "- Prometheus: http://$MINIKUBE_IP:30090 (if NodePort is configured)"
    echo "- Grafana: http://$MINIKUBE_IP:30300 (if NodePort is configured)"
    
    # Alternative access methods
    echo ""
    echo "Alternatively, you can use these commands to access services:"
    echo "- API:        minikube service image-classifier -n $NAMESPACE --url"
    echo "- Prometheus: minikube service prometheus -n $NAMESPACE --url"
    echo "- Grafana:    minikube service grafana -n $NAMESPACE --url"
    
    # Check if minikube tunnel is running
    if ! ps aux | grep -q "[m]inikube tunnel"; then
        echo -e "\nTip: For LoadBalancer services and Ingress to work, run 'minikube tunnel' in a separate terminal"
    fi
else
    echo "- API: http://<cluster-ip>/api/v1"
    echo "- Prometheus: http://<cluster-ip>:9090"
    echo "- Grafana: http://<cluster-ip>:3000 (admin/admin)"
fi

# Print pods status
echo -e "\nPods status:"
kubectl get pods -n $NAMESPACE

# Optional debug info
if [ "$DEBUG" == "true" ]; then
    echo -e "\nDetailed service info:"
    kubectl get svc -n $NAMESPACE -o wide
    echo -e "\nDetailed ingress info:"
    kubectl get ingress -n $NAMESPACE -o wide
fi 

