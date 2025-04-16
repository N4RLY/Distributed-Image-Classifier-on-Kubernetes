#!/bin/bash

# Exit on error
set -e

# Configuration
NAMESPACE="image-classifier"

echo "===== Cleaning up Image Classifier from Kubernetes ====="
echo "Namespace: $NAMESPACE"

# Check if namespace exists
if kubectl get namespace $NAMESPACE &> /dev/null; then
    # Delete all resources in the namespace
    echo "Deleting all resources in namespace: $NAMESPACE"
    
    # Delete HPA first (to avoid conflicts)
    kubectl delete hpa --all -n $NAMESPACE --ignore-not-found=true
    
    # Delete other resources
    kubectl delete deployment --all -n $NAMESPACE --ignore-not-found=true
    kubectl delete service --all -n $NAMESPACE --ignore-not-found=true
    kubectl delete ingress --all -n $NAMESPACE --ignore-not-found=true
    kubectl delete configmap --all -n $NAMESPACE --ignore-not-found=true
    
    # Ask if namespace should be deleted
    read -p "Do you want to delete the namespace as well? (y/n): " DELETE_NS
    if [[ $DELETE_NS == "y" || $DELETE_NS == "Y" ]]; then
        echo "Deleting namespace: $NAMESPACE"
        kubectl delete namespace $NAMESPACE
    else
        echo "Namespace $NAMESPACE kept intact."
    fi
else
    echo "Namespace $NAMESPACE does not exist. Nothing to clean up."
fi

echo "===== Cleanup Completed =====" 