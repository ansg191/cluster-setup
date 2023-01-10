# Anshul Gupta Cluster Setup

Anshul's Kubernetes cluster setup on GKE managed using Terraform and Helm.

## WARNING
This repository is no longer being updated. 
Cluster configuration will be managed using Terraform, Helm, & Flux at https://github.com/ansg191/anshulg-cluster.

## Applications

 - Traefik Ingress reverse proxy
 - cert-manager to manage & renew certificates
 - 1Password operator to handle secrets
 - step-ca Root CA
 - Gitea Git server
 - Drone CI Server
 - Datadog metrics & log collection
 - Verdaccio npm proxy
 - Socks5 proxy
 - FPRS tunnel for personal servers at home
    - Solves problem of NAT blocking connections & ISP blocking port 80 & 443
    - All external traffic is still encrypted using TLS
 - NFS Shared Drive

