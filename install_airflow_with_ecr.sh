# Create or replace a Kind cluster
kind delete cluster --name kind
kind create cluster --image kindest/node:v1.29.4

# Add Airflow to Helm repositories
helm repo add apache-airflow https://airflow.apache.org
helm repo update
helm show values apache-airflow/airflow > chart/values-example.yaml

# Export values for Airflow docker image
export REGION=us-east-1
export ECR_REGISTRY=430197276879.dkr.ecr.us-east-1.amazonaws.com
export ECR_REPO=my-dags
export NAMESPACE=airflow
export RELEASE_NAME=airflow

# Authenticate with ECR
aws ecr get-login-password --region $REGION \
  | docker login --username AWS --password-stdin $ECR_REGISTRY

# Get the latest image tag from ECR
export IMAGE_TAG=$(aws ecr list-images --repository-name my-dags --region us-east-1 --query 'imageIds[*].imageTag' --output text | tr '\t' '\n' | sort -r | head -n 1)

# Load it into kind
docker pull $ECR_REGISTRY/$ECR_REPO:$IMAGE_TAG
kind load docker-image $ECR_REGISTRY/$ECR_REPO:$IMAGE_TAG

# Create namespace
kubectl create namespace $NAMESPACE

# Apply Kubernetes configurations
kubectl apply -f k8s/secrets/git-secrets.yaml

helm install $RELEASE_NAME apache-airflow/airflow \
    --namespace $NAMESPACE -f chart/values-override.yaml \
    --set-string images.airflow.tag="$IMAGE_TAG" \
    --debug

# Port-forward Airflow API server
kubectl port-forward svc/$RELEASE_NAME-api-server 8080:8080 -n $NAMESPACE
