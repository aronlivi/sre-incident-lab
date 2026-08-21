#!/usr/bin/env bash

set -euo pipefail

METRICS_SERVER_VERSION="v0.9.0"

echo "Installing Metrics Server ${METRICS_SERVER_VERSION}..."

kubectl apply -f \
  "https://github.com/kubernetes-sigs/metrics-server/releases/download/${METRICS_SERVER_VERSION}/components.yaml"

echo "Configuring Metrics Server for local kind cluster..."

kubectl patch deployment metrics-server \
  -n kube-system \
  --type='json' \
  -p='[
    {
      "op":"add",
      "path":"/spec/template/spec/containers/0/args/-",
      "value":"--kubelet-insecure-tls"
    }
  ]'

echo "Waiting for Metrics Server rollout..."

kubectl rollout status \
  deployment/metrics-server \
  -n kube-system

echo
echo "Metrics Server installed."

kubectl get apiservice \
  v1beta1.metrics.k8s.io
