# Export values for Airflow docker image
export IMAGE_NAME=my-dags
export NAMESPACE=airflow
export RELEASE_NAME=airflow
export IMAGE_TAG=$(date +%Y%m%d%H%M%S)

# Re-build image and load it into Kind
docker build --pull --tag $IMAGE_NAME:$IMAGE_TAG -f cicd/Dockerfile .
kind load docker-image $IMAGE_NAME:$IMAGE_TAG

# Upgrade Airflow deployment using Helm
helm upgrade $RELEASE_NAME apache-airflow/airflow \
    --namespace $NAMESPACE \
    -f chart/values-override.yaml \
    --set-string images.airflow.tag="$IMAGE_TAG" \
    --debug

# Port-forward Airflow API server
kubectl port-forward svc/$RELEASE_NAME-api-server 8080:8080 -n $NAMESPACE
