# Monitoring with Prometheus and Grafana

This project includes a complete monitoring stack using Prometheus and Grafana to help you observe the performance and health of your distributed image classifier.

## Components

- **Prometheus**: Collects and stores metrics from the application
- **Grafana**: Provides visualization of metrics through dashboards

## Key Metrics Monitored

- API request throughput and response latency
- Pod scaling behavior (count, CPU, memory)
- Model inference time for image classification
- Error rates and network traffic

## Accessing the Monitoring Dashboard

### Using Minikube

```bash
# Get Prometheus URL
minikube service prometheus -n image-classifier --url

# Get Grafana URL
minikube service grafana -n image-classifier --url
```

### Using Port Forwarding

```bash
# Forward Prometheus (default port 9090)
kubectl port-forward svc/prometheus 9090:9090 -n image-classifier

# Forward Grafana (default port 3000)
kubectl port-forward svc/grafana 3000:3000 -n image-classifier
```

Then access:
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (login with admin/admin)

## Grafana Login

- Username: admin
- Password: admin

When you first log in, Grafana will prompt you to change the default password.

## Viewing Dashboards

1. After logging in to Grafana, click on the "Home" dashboard dropdown menu
2. Select "Image Classifier Performance Dashboard" from the list
3. You should see metrics for API request rate, latency, pod scaling, and more

## Troubleshooting

If you don't see metrics in Prometheus or Grafana:

1. Verify that the "api" service is running:
   ```bash
   kubectl get svc api -n image-classifier
   ```

2. Check Prometheus targets to ensure metrics are being scraped:
   ```bash
   # Access Prometheus UI
   minikube service prometheus -n image-classifier --url
   ```
   Then go to Status > Targets and verify "docker-image-classifier" is UP.

3. Generate traffic to the API to produce metrics:
   ```bash
   # Example to generate traffic
   curl -X POST -F "file=@/path/to/image.jpg" http://$(minikube service image-classifier -n image-classifier --url)/api/v1/classify
   ```

4. If problems persist, you can restart Prometheus:
   ```bash
   kubectl rollout restart deployment prometheus -n image-classifier
   ```

## Configuration Details

The monitoring setup includes:

- Prometheus configured to scrape the /metrics endpoint from the image classifier
- A dedicated "api" service that Prometheus can use to reliably reach the metrics endpoint
- A pre-configured Grafana dashboard that visualizes all key metrics
- Auto-provisioning of datasources and dashboards for easy setup 