# Architecture Overview

This document describes the architecture of the distributed image classifier system.

## System Architecture

The image classifier is built using a microservices architecture deployed on Kubernetes, with the following components:

![Architecture Diagram](../assets/architecture_diagram.png)

### Key Components

1. **API Service**
   - FastAPI web server that handles HTTP requests
   - Exposes RESTful endpoints for image classification
   - Implements middleware for monitoring and metrics collection

2. **Classification Engine**
   - TensorFlow-based image classification using MobileNetV2
   - Pre-trained on the ImageNet dataset
   - Optimized for efficient inference

3. **Load Balancer / Ingress**
   - Distributes incoming traffic across API service instances
   - Manages TLS termination
   - Routes requests to appropriate services

4. **Monitoring Stack**
   - Prometheus for metrics collection and storage
   - Grafana for visualization and dashboards
   - Custom metrics for throughput and latency tracking

5. **Auto-scaling**
   - Horizontal Pod Autoscaler (HPA) for automatic scaling
   - Scales based on CPU/memory utilization and custom metrics
   - Ensures efficient resource utilization during varying load

## Request Flow

1. Client sends an HTTP POST request with an image to the API service
2. API service validates the request and image format
3. Image is preprocessed to match the model's input requirements
4. The model performs inference to classify the image
5. Results are formatted and returned to the client
6. Metrics about the request are collected by Prometheus

## Scaling Behavior

The system is designed to scale horizontally based on load:

- At **low load**, the system runs with a minimum of 2 replicas
- As **load increases**, the HPA increases the number of pods based on CPU/memory utilization
- During **peak load**, the system can scale up to 10 replicas
- As **load decreases**, pods are gracefully terminated to conserve resources

## Monitoring and Metrics

### Key Metrics Tracked

1. **Request Throughput**
   - Total requests per second
   - Requests per endpoint
   - Success/failure rates

2. **Latency**
   - API request latency (end-to-end)
   - Model inference latency
   - Percentile distributions (p50, p95, p99)

3. **Resource Utilization**
   - CPU usage per pod
   - Memory consumption
   - Network I/O

### Dashboards

Custom Grafana dashboards provide visibility into:

- System performance
- Scaling behavior
- Error rates
- Resource utilization

## Deployment Strategy

The system uses a rolling update deployment strategy to ensure zero-downtime updates:

1. New version is deployed alongside the existing version
2. Traffic is gradually shifted to the new version
3. Old version is decommissioned after successful deployment

## Data Flow Diagram

```
┌─────────┐     ┌─────────┐     ┌─────────────────┐     ┌─────────────────┐
│         │     │         │     │                 │     │                 │
│ Client  ├────►│ Ingress ├────►│ API Service Pod ├────►│ Classification  │
│         │     │         │     │                 │     │ Engine          │
└─────────┘     └─────────┘     └────────┬────────┘     └─────────────────┘
                                         │
                                         ▼
                              ┌────────────────────┐
                              │                    │
                              │ Prometheus Metrics │
                              │                    │
                              └──────────┬─────────┘
                                         │
                                         ▼
                              ┌────────────────────┐
                              │                    │
                              │ Grafana Dashboard  │
                              │                    │
                              └────────────────────┘
```

## Security Considerations

- API access controls for admin endpoints
- Input validation to prevent malicious uploads
- Resource limits to prevent DoS attacks
- Network policies for internal service communication

## Future Enhancements

1. **Model Serving**
   - Implement TensorFlow Serving for more efficient model serving
   - Support for model versioning and A/B testing

2. **Caching Layer**
   - Add Redis/Memcached for caching frequent classification requests
   - Reduce duplicate processing of identical images

3. **Distributed Tracing**
   - Implement OpenTelemetry for distributed tracing
   - Improve debugging and performance analysis

4. **Custom Metrics Autoscaling**
   - Scale based on request latency or queue depth
   - More intelligent scaling decisions based on actual load patterns 