#!/bin/bash

# Exit on error
set -e

# Configuration
NAMESPACE="image-classifier"
SERVICE_NAME="image-classifier"
TEST_IMAGE_PATH="load-testing/test-images/images.jpeg"

# Default values
HOST="localhost"
PORT=""

# Parse command line arguments
while getopts "h:p:" opt; do
  case $opt in
    h) HOST="$OPTARG" ;;
    p) PORT="$OPTARG" ;;
    *) echo "Usage: $0 [-h host] -p port" >&2
       echo "Default host is localhost if not specified"
       exit 1 ;;
  esac
done

echo "===== Generating test traffic for Image Classifier ====="

# Check if test image exists
if [ ! -f "$TEST_IMAGE_PATH" ]; then
    echo "Error: Test image not found at $TEST_IMAGE_PATH"
    echo "Please place a test image in the load-testing/test-images directory"
    exit 1
fi

# Check if port is provided
if [ -z "$PORT" ]; then
    echo "Error: PORT not provided"
    echo "Usage: $0 [-h host] -p port"
    echo "Example: $0 -h localhost -p 8000"
    echo "Default host is localhost if not specified"
    exit 1
fi

SERVICE_URL="http://${HOST}:${PORT}"

# Generate test traffic
echo "Sending requests to: $SERVICE_URL/api/v1/classify"
echo "Using test image: $TEST_IMAGE_PATH"
echo "Sending 20 requests with 1 second interval..."

for i in {1..100}; do
    echo -n "Request $i: "
    RESPONSE=$(curl -s -X POST -F "file=@$TEST_IMAGE_PATH" $SERVICE_URL/api/v1/classify)
    echo "$RESPONSE" | grep -o '"execution_time_ms":[0-9.]\+' || echo "Failed"
    sleep 0.1
done

echo "===== Test traffic completed ====="