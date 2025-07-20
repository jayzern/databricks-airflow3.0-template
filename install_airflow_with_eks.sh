# Create EKS cluster with eksctl
eksctl create cluster --name airflow --region us-east-1 --nodegroup-name standard-workers --node-type t3.medium --nodes 3 --nodes-min 1 --nodes-max 4 --managed

# Set up kubectl to use the new EKS cluster
aws eks --region us-east-1 update-kubeconfig --name airflow