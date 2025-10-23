# High Availability Kubernetes Cluster on Azure with Terraform
### Project Overview
This project demonstrates the provisioning of a high availability (HA) Kubernetes cluster on Microsoft Azure using Terraform as the Infrastructure as Code (IaC) tool. The setup includes 5 virtual machines (VMs): 2 master nodes, 2 worker nodes, and 1 additional VM for hosting HAProxy as a dedicated load balancer and control plane proxy.
Key features:
High Availability: Achieved through redundant master and worker nodes, with HAProxy handling failover for the Kubernetes control plane and load balancing for application traffic.
Kubernetes Cluster: A multi-master setup for resilience.
Applications: Deployment of two Spring Boot web applications to showcase workload distribution.
Automation: All infrastructure is provisioned via Terraform, with scripts for cluster bootstrapping.

Architecture
The architecture is designed for high availability, scalability, and fault tolerance:
![Architecture]()
Azure Resources:
5 VMs (e.g., Standard_D2_v3 size) in a Virtual Network (VNet) with subnets for isolation.
Network Security Groups (NSGs) for controlled access (e.g., SSH on port 22, Kubernetes API on 6443, HAProxy ports).
Public IP for the HAProxy VM to act as an entry point.

Kubernetes Cluster:
Master Nodes (2): Run the control plane components (etcd, kube-apiserver, kube-scheduler, kube-controller-manager). Configured in HA mode with etcd clustering.
Worker Nodes (2): Run workloads (pods) with kubelet and kube-proxy.
HAProxy Node (1): Acts as a proxy for the Kubernetes API server (for masters) and as a load balancer for application traffic to workers.


HA Components:
HAProxy load balances API requests across master nodes.
For workers, HAProxy distributes HTTP/HTTPS traffic to deployed applications.


Applications:
Two Spring Boot web apps deployed as Deployments with Services (type LoadBalancer or NodePort, proxied via HAProxy).
