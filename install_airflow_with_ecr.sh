# Create or replace a Kind cluster
kind delete cluster --name kind
kind create cluster --image kindest/node:v1.29.4

# Add Airflow to Helm repositories
helm repo add apache-airflow https://airflow.apache.org
helm repo update
helm show values apache-airflow/airflow > chart/values-example.yaml

# Export values for Airflow docker image
export IMAGE_NAME=my-dags
export IMAGE_TAG=$(date +%Y%m%d%H%M%S)
export NAMESPACE=airflow
export RELEASE_NAME=airflow

# Build image and load it into Kind
docker build --pull --tag $IMAGE_NAME:$IMAGE_TAG -f cicd/Dockerfile .
kind load docker-image $IMAGE_NAME:$IMAGE_TAG

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
