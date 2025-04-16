# Distributed Image Classifier on Kubernetes

This project deploys a scalable image classification microservice on Kubernetes. The service accepts image uploads through a RESTful API and returns classification results using a pre-trained deep learning model.

## Project Structure

```
.
├── app/                          # Application code
│   ├── classifier/               # Image classification logic
│   │   ├── model.py              # Classification model implementation
│   │   └── utils.py              # Helper functions for classification
│   ├── api/                      # API endpoints
│   │   ├── routes.py             # API route definitions
│   │   └── middleware.py         # Request processing middleware
│   ├── config.py                 # Application configuration
│   ├── main.py                   # Main application entry point
│   └── requirements.txt          # Python dependencies
├── kubernetes/                   # Kubernetes manifests
│   ├── deployment.yaml           # Pod deployment configuration
│   ├── service.yaml              # Service configuration
│   ├── ingress.yaml              # Ingress configuration
│   ├── hpa.yaml                  # Horizontal Pod Autoscaler
│   └── configmap.yaml            # ConfigMap for application settings
├── monitoring/                   # Monitoring setup
│   ├── prometheus/               # Prometheus configuration
│   │   └── prometheus.yaml       # Prometheus deployment
│   ├── grafana/                  # Grafana configuration
│   │   ├── grafana.yaml          # Grafana deployment
│   │   └── dashboards/           # Dashboard configurations
│   └── metrics-server/           # Metrics Server for HPA
├── load-testing/                 # Load testing scripts
│   ├── locust/                   # Locust load testing tool
│   │   ├── locustfile.py         # Load test definition
│   │   └── requirements.txt      # Locust dependencies
│   └── test-images/              # Sample images for testing
├── docs/                         # Documentation
│   ├── setup.md                  # Setup instructions
│   └── architecture.md           # Architecture overview
├── scripts/                      # Helper scripts
│   ├── deploy.sh                 # Deployment script
│   └── cleanup.sh                # Cleanup script
├── Dockerfile                    # Docker image definition
├── docker-compose.yml            # Local development setup
└── README.md                     # Project documentation
```

## Implementation Plan

### Phase 1: Application Development
1. Create a Python FastAPI application for image classification
2. Integrate a pre-trained model (e.g., ResNet, MobileNet via TensorFlow/PyTorch)
3. Implement API endpoints for image upload and classification
4. Containerize the application using Docker
5. Set up local testing environment with docker-compose

### Phase 2: Kubernetes Deployment
1. Create Kubernetes manifests for deployment, service, and ingress
2. Configure Horizontal Pod Autoscaler (HPA) for scaling
3. Set up ConfigMaps for application configuration
4. Deploy the application to a Kubernetes cluster (Minikube or cloud provider)

### Phase 3: Monitoring and Metrics
1. Deploy Prometheus and Grafana for monitoring
2. Configure custom metrics for tracking request throughput and latency
3. Create Grafana dashboards for visualization
4. Set up metrics-server for HPA resource metrics

### Phase 4: Load Testing and Validation
1. Implement load testing scripts using Locust
2. Simulate high traffic to test autoscaling behavior
3. Collect and analyze performance metrics
4. Document findings and optimization opportunities

## Validation Checklist

- [ ] Track request throughput and response latency
  - Set up Prometheus metrics in the application
  - Create Grafana dashboard panels for throughput and latency

- [ ] Simulate high load and monitor pod scaling behavior
  - Execute load testing with Locust
  - Verify HPA properly scales pods based on load
  - Document scaling behavior with screenshots

- [ ] Record system metrics and dashboard snapshots
  - Capture CPU, memory, and network usage
  - Save dashboard snapshots at different load levels
  - Document correlation between load and resource utilization

## Technical Stack

- **Programming Language**: Python 3.9+
- **Web Framework**: FastAPI
- **ML Frameworks**: TensorFlow or PyTorch
- **Container Runtime**: Docker
- **Orchestration**: Kubernetes
- **API Gateway**: Nginx or Traefik
- **Monitoring**: Prometheus, Grafana
- **Load Testing**: Locust

## Study Resources

### Kubernetes
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Kubernetes: Up and Running](https://www.oreilly.com/library/view/kubernetes-up-and/9781492046523/)
- [Kubernetes Patterns](https://www.redhat.com/en/resources/oreilly-kubernetes-patterns-cloud-native-apps)

### Machine Learning & Model Deployment
- [TensorFlow Serving](https://www.tensorflow.org/tfx/guide/serving)
- [PyTorch Model Deployment](https://pytorch.org/tutorials/beginner/saving_loading_models.html)
- [ML Model Deployment Strategies](https://www.seldon.io/ml-model-deployment-strategies)

### Monitoring and Metrics
- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)
- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Cloud Native Monitoring](https://sre.google/sre-book/monitoring-distributed-systems/)

### Load Testing
- [Locust Documentation](https://docs.locust.io/en/stable/)
- [Distributed Load Testing Patterns](https://cloud.google.com/architecture/distributed-load-testing-using-gke)

### FastAPI
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Building Data Science APIs](https://fastapi.tiangolo.com/tutorial/first-steps/)

## Local Development Setup

1. Install Docker and docker-compose
2. Clone this repository
3. Build and run the application:
   ```
   docker-compose up --build
   ```
4. Access the API at http://localhost:8000
5. View API documentation at http://localhost:8000/docs

## Kubernetes Deployment

1. Install kubectl and set up a Kubernetes cluster
2. Apply the Kubernetes manifests:
   ```
   kubectl apply -f kubernetes/
   ```
3. Deploy monitoring stack:
   ```
   kubectl apply -f monitoring/
   ```
4. Access the application through configured ingress

## License

This project is available under the MIT License. See the LICENSE file for more details. 