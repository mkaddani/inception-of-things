#!/usr/bin/env bash

# Part Three starting

# Delete existing K3D cluster if it exists
k3d cluster delete mkaddani-cluster

## Create k3d cluster and merge it with kubeconfig so kubectl works fine -----------------------------------------------
echo "===============================[K3D mkaddani-cluster set-up]========================================="
k3d cluster create mkaddani-cluster --port 80:80@loadbalancer --port 443:443@loadbalancer --servers 1 --agents 2
k3d kubeconfig merge mkaddani-cluster --kubeconfig-switch-context
sleep 6
kubectl get pods --all-namespaces

## Create the NameSpaces - soft isolation -----------------------------------------------------------------------------
echo "===============================[K3D mkaddani-cluster Create NameSpaces]=============================="
kubectl create ns argocd
kubectl create ns dev
kubectl create ns gitlab
kubectl get namespaces

### Install GitLab -----------------------------------------------------------------------------------------------------
helm repo add gitlab http://charts.gitlab.io/
helm install gitlab gitlab/gitlab -n gitlab -f ../confs/values.yaml \
  --set certmanager-issuer.email=mkaddani@staff.42.ft \
  --set global.hosts.domain=local.com \
  --set global.hosts.externalIP=0.0.0.0 \
  --set global.hosts.https=false \
  --set global.edition=ce \
  --timeout 600m

### ScaleDown Resources -------------------------------------------------------------------------------------------------
# Uncomment to scale down resources in the GitLab namespace
# NAMESPACE="gitlab"
# LOGFILE="/dev/null"

# Create or clear the log file
# > $LOGFILE

# Log a timestamp and start message
# echo "Scaling started at $(date)" | tee -a $LOGFILE

# Scale all deployments to 1 replica
# DEPLOYMENTS=$(kubectl get deployments -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
# for DEPLOYMENT in $DEPLOYMENTS; do
#   echo "Scaling deployment $DEPLOYMENT to 1 replica..." | tee -a $LOGFILE
#   kubectl scale deployment $DEPLOYMENT --replicas=1 -n $NAMESPACE 2>&1 | tee -a $LOGFILE
# done

# Scale all statefulsets to 1 replica
# STATEFULSETS=$(kubectl get statefulsets -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
# for STATEFULSET in $STATEFULSETS; do
#   echo "Scaling statefulset $STATEFULSET to 1 replica..." | tee -a $LOGFILE
#   kubectl scale statefulset $STATEFULSET --replicas=1 -n $NAMESPACE 2>&1 | tee -a $LOGFILE
# done

# Scale all horizontal pod autoscalers to minPods=1 and maxPods=1
# HPAS=$(kubectl get hpa -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
# for HPA in $HPAS; do
#   echo "Scaling HPA $HPA to minReplicas=1 and maxReplicas=1..." | tee -a $LOGFILE
#   kubectl patch hpa $HPA --patch '{"spec": {"minReplicas": 1, "maxReplicas": 1}}' -n $NAMESPACE 2>&1 | tee -a $LOGFILE
# done

# Log a completion message
# echo "Scaling completed at $(date)" | tee -a $LOGFILE

### ScaleDown Resources -------------------------------------------------------------------------------------------------
# Uncomment to restart GitLab deployments
# kubectl rollout restart deployment.apps/gitlab-gitlab-runner -n gitlab
# kubectl rollout restart deployment.apps/gitlab-webservice-default -n gitlab

### Applying ingress for GitLab
kubectl apply -f ../confs/ingress.gitlab.yaml

#-------------------------------------------------------------------------------------------------------------------
echo waiting for GitLab at www.gitlab.local.com
while true; do
  if curl -s -o /dev/null -w "%{http_code}\n" http://www.gitlab.local.com/users/sign_in | grep -q '200'; then
    echo "GitLab is up!"
    break  # Exit the loop if the link is accessible
  else
    echo "GitLab is not up yet ..."
  fi
  sleep 5  # Wait for 5 seconds before the next check
done
#-------------------------------------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------------------------------------------
echo Please create a Public repo at www.gitlab.local.com/root/mkaddani-ops-demo Manually
while true; do
  if curl -s -o /dev/null -w "%{http_code}\n" http://www.gitlab.local.com/root/mkaddani-ops-demo | grep -q '200'; then
    echo "Repo is Public!"
    break  # Exit the loop if the link is accessible
  else
    echo "Repo is not public."
  fi
  sleep 5  # Wait for 5 seconds before the next check
done
#-------------------------------------------------------------------------------------------------------------------

### Get GitLab Credentials
MYGITLABUSER="root"
MYGITLABPASS=$(kubectl get secret -n gitlab gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode)
SCRIPTPATH=$PWD

# Set variables
GITHUB_REPO="https://github.com/mkaddani42/mkaddani-ops-demo"
GITLAB_USERNAME=$MYGITLABUSER  # Replace with your actual GitLab username
GITLAB_PASSWORD=$MYGITLABPASS  # Replace with your actual GitLab password
GITLAB_REPO_URL="www.gitlab.local.com/root/mkaddani-ops-demo.git"  # Replace with your actual GitLab repo URL
WORK_DIR="/tmp/mkaddani-ops-demo-clone"

# Clone the GitHub repository
git clone $GITHUB_REPO $WORK_DIR

# Change to the cloned repository directory
cd $WORK_DIR

# Add GitLab remote with username and password
echo git remote add gitlab "http://$GITLAB_USERNAME:$GITLAB_PASSWORD@$GITLAB_REPO_URL"
git remote add gitlab "http://$GITLAB_USERNAME:$GITLAB_PASSWORD@$GITLAB_REPO_URL"

# Push to GitLab
git push -u gitlab main

# Remove the cloned repository
cd ..
rm -rf $WORK_DIR
cd $SCRIPTPATH
echo "Cloned, pushed, and cleaned up successfully!"  
#-------------------------------------------------------------------------------------------------------------------
echo checking the repo at www.gitlab.local.com/root/mkaddani-ops-demo Public status
while true; do
  if curl -s -o /dev/null -w "%{http_code}\n" http://www.gitlab.local.com/root/mkaddani-ops-demo | grep -q '200'; then
    echo "OK!"
    break  # Exit the loop if the link is accessible
  else
    echo "Not OK!"
  fi
  sleep 5  # Wait for 5 seconds before the next check
done
#-------------------------------------------------------------------------------------------------------------------

### Install ArgoCD
kubectl apply -n argocd -f ../confs/argocd.install.yaml
sleep 5
while kubectl get endpoints -n argocd | grep '<none>' > /dev/null; do echo "Waiting for ArgoCD endpoints to be ready..."; sleep 1; done; echo "Endpoint is ready!"
kubectl apply -f ../confs/ingress.argocd.yaml

#-------------------------------------------------------------------------------------------------------------------
echo waiting for ArgoCD at www.argocd.local.com
while true; do
  if curl -s -o /dev/null -w "%{http_code}\n" http://www.argocd.local.com/ | grep -q '200'; then
    echo "ArgoCD is up!"
    break  # Exit the loop if the link is accessible
  else
    echo "ArgoCD ..."
  fi
  sleep 5  # Wait for 5 seconds before the next check
done
#-------------------------------------------------------------------------------------------------------------------

kubectl apply -f ../confs/app1.argocd.yaml

### Setup ingress for WillApp
kubectl apply -f ../confs/ingress.willapp.yaml

### Credentials
echo '==========================[GitLab]=================================='
echo www.gitlab.local.com
echo gitlab user: root
echo gitlab password: $(kubectl get secret -n gitlab gitlab-gitlab-initial-root-password -o jsonpath='{.data.password}' | base64 --decode)
echo '==========================[ArgoCD]=================================='
echo www.argocd.local.com
echo Please use these credentials
echo ArgoCD user: admin
echo ArgoCD password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo '==========================[WillAPP]=================================='
echo www.willapp.local.com
