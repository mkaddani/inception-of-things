#!/usr/bin/env bash


echo '==========================[GitLab]=================================='
echo www.gitlab.local.com
echo gitlab user: root
echo gitlab password: $(kubectl get secret -n gitlab gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode)
echo '==========================[ArgoCD]=================================='
echo www.argocd.local.com
echo Please use this credentials 
echo ArgoCD user: admin
echo ArgoCD password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo '==========================[WillAPP]=================================='
echo www.willapp.local.com
