import os
import time
import random
from locust import HttpUser, task, between
from locust.exception import RescheduleTask
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Path to test images directory
TEST_IMAGES_DIR = os.getenv("TEST_IMAGES_DIR", "../test-images")

class ImageClassifierUser(HttpUser):
    wait_time = between(1, 3)  # Wait between 1-3 seconds between tasks
    
    def on_start(self):
        """
        Load test images when the user starts
        """
        self.images = []
        self.image_files = []
        
        # Load test images
        if os.path.exists(TEST_IMAGES_DIR):
            for filename in os.listdir(TEST_IMAGES_DIR):
                if filename.lower().endswith(('.jpg', '.jpeg', '.png')):
                    image_path = os.path.join(TEST_IMAGES_DIR, filename)
                    try:
                        with open(image_path, "rb") as f:
                            self.images.append((filename, f.read()))
                            self.image_files.append(filename)
                    except Exception as e:
                        logger.error(f"Error loading image {filename}: {str(e)}")
        
        if not self.images:
            logger.warning(f"No test images found in {TEST_IMAGES_DIR}. Make sure to add some test images.")
            
        logger.info(f"Loaded {len(self.images)} test images")
    
    @task(10)
    def classify_image(self):
        """
        Main task: Classify a random image
        """
        if not self.images:
            logger.warning("No test images available, skipping test")
            raise RescheduleTask()
        
        # Select a random image
        idx = random.randint(0, len(self.images) - 1)
        filename, image_data = self.images[idx]
        
        # Record start time for client-side latency measurement
        start_time = time.time()
        
        # Send request to classify the image
        with self.client.post(
            "/api/v1/classify",
            files={"file": (filename, image_data, "image/jpeg")},
            catch_response=True
        ) as response:
            # Calculate client-side latency
            latency = time.time() - start_time
            
            if response.status_code == 200:
                # Request succeeded
                result = response.json()
                prediction_count = len(result.get("predictions", []))
                execution_time = result.get("metadata", {}).get("execution_time_ms", 0)
                
                logger.debug(f"Successfully classified {filename} with {prediction_count} predictions")
                logger.debug(f"Server execution time: {execution_time}ms, Client latency: {latency*1000:.2f}ms")
                
                response.success()
            else:
                # Request failed
                logger.error(f"Failed to classify {filename}: {response.status_code} - {response.text}")
                response.failure(f"Failed with status code: {response.status_code}")
    
    @task(1)
    def get_health(self):
        """
        Periodic health check task
        """
        with self.client.get("/health", catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Health check failed: {response.status_code}")
                
    @task(1)
    def get_metrics_summary(self):
        """
        Get metrics summary
        """
        with self.client.get("/api/v1/metrics/summary", catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Metrics summary failed: {response.status_code}") 