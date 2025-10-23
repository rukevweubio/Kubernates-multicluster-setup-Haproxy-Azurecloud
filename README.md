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
![Architecture](https://github.com/rukevweubio/Kubernates-multicluster-setup-Haproxy-Azurecloud/blob/main/diagram-export-22-10-2025-20_28_38.png)

Azure Resources:
- 5 VMs (e.g., Standard_D2_v3 size) in a Virtual Network (VNet) with subnets for isolation.
- Network Security Groups (NSGs) for controlled access (e.g., SSH on port 22, Kubernetes API on 6443, HAProxy ports).
- Public IP for the HAProxy VM to act as an entry point.

Kubernetes Cluster 
- Master Nodes (2): Run the control plane components (etcd, kube-apiserver, kube-scheduler, kube-controller-manager). Configured in HA mode with etcd clustering.
- Worker Nodes (2): Run workloads (pods) with kubelet and kube-proxy.
- HAProxy Node (1): Acts as a proxy for the Kubernetes API server (for masters) and as a load balancer for application traffic to workers.


HA Components:
- HAProxy load balances API requests across master nodes.
- For workers, HAProxy distributes HTTP/HTTPS traffic to deployed applications.


Applications:
- Two Spring Boot web apps deployed as Deployments with Services (type LoadBalancer or NodePort, proxied via HAProxy).

### Prerequisites
Before setting up the project, ensure you have:

- An Azure account with sufficient credits/subscription.
- Azure CLI installed and authenticated (az login).
- Terraform installed (version >= 1.0).
- kubectl installed for Kubernetes management.
- SSH key pair for VM access (generate with ssh-keygen).
- Git cloned repository: git clone <repo-url>.
- Basic knowledge of Terraform, Kubernetes, and HAProxy.

Required environment variables:
- AZURE_SUBSCRIPTION_ID
- AZURE_TENANT_ID
- AZURE_CLIENT_ID
- AZURE_CLIENT_SECRET (for service principal authentication).

Terraform Configuration:
- The Terraform code is located in the terraform/ directory. Key files:
- main.tf: Defines providers, resources (VMs, VNet, NSGs).
- variables.tf: Customizable variables (e.g., VM size, region).
- outputs.tf: Outputs like VM IPs, HAProxy endpoint.
- provider.tf: Azure provider configuration.


```
variable "resource_group" {
  type        = string
  description = "Azure Resource Group name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "vnet_name" {
  type        = string
  description = "VNet name"
}

variable "vnet_cidr" {
  type        = string
  description = "VNet CIDR block"
}

variable "subnet_name" {
  type        = string
  description = "Subnet name"
}

variable "subnet_cidr" {
  type        = string
  description = "Subnet CIDR block"
}

variable "admin_username" {
  type        = string
  description = "Admin username"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key"
}

variable "master_ips" {
  type        = list(string)
  description = "Private IPs for master nodes"
}

variable "worker_ips" {
  type        = list(string)
  description = "Private IPs for worker nodes"
}

variable "haproxy_ip" {
  type        = string
  description = "Private IP for HAProxy node"
}
```
### Provisioning VMs on Azure
- cd terraform  directory
- terraform init
- terraform validate
- terraform plan
- terraform apply -auto-approve
  
![terraform provision](https://github.com/rukevweubio/Kubernates-multicluster-setup-Haproxy-Azurecloud/blob/main/photo/Screenshot%20(2688).png)

### This provisions:
- Resource Group.
- VNet and Subnets.
- 5 VMs with Ubuntu 20.04 LTS (or specified OS).
- SSH access configured with your public key.
- Basic user data scripts for initial setup (e.g., installing dependencies).
### Outputs will include IPs:
- master_ips: Array of master node private IPs.
- worker_ips: Array of worker node private IPs.
- haproxy_ip: Public IP of HAProxy VM.
- 
![terraform provision](https://github.com/rukevweubio/Kubernates-multicluster-setup-Haproxy-Azurecloud/blob/main/photo/Screenshot%20(2692).png)


### Log In to the Azure VMs
- To access the VMs, you need the public IP of the HAProxy VM and private IPs of the master/worker nodes, as well as the SSH key pair used during Terraform provisioning.
- Terraform outputs: Run terraform output in the terraform/ directory to get:
-  in the project i used password and username 
- Azure CLI or access to Azure Portal to verify VM details if needed.
- copy the username and teh public ip of the vm .
- login  into your console  and input teh password  from the terrafrom script

![terraform output ip address to login](https://github.com/rukevweubio/Kubernates-multicluster-setup-Haproxy-Azurecloud/blob/main/photo/Screenshot%20(2702).png)


### Install HAProxy on the HAProxy VM
- You are logged into the HAProxy VM username  nd password 
- Update the Package Index:
- Install HAProxy:
```
sudo apt insatll haproxy -y.
 sudo systemctl status haproxy .
haproxy -v
sudo systemctl enable haproxy
sudo systemctl status haproxy
haproxy -f /etc/haproxy/haproxy.cfg -c
sudo systemctl restart haproxy
-----------
sudo nano /etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    log /dev/log local1 notice
    daemon
    maxconn 2048
    user haproxy
    group haproxy

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    retries 3
    timeout connect 5s
    timeout client  50s
    timeout server  50s


frontend kubernetes_api_frontend
    bind *:6443
    mode tcp
    option tcplog
    default_backend kubernetes_api_backend

backend kubernetes_api_backend
    mode tcp
    balance roundrobin
    option tcp-check
    server master-1 10.0.1.5:6443 check fall 3 rise 2
    server master-2 10.0.1.6:6443 check fall 3 rise 2


frontend nodeport_frontend
    bind *:80
    mode tcp
    option tcplog
    default_backend nodeport_backend

backend nodeport_backend
    mode tcp
    balance roundrobin
    server worker-1 10.0.1.7:30080 check
    server worker-2 10.0.1.8:30080 check
    server worker-3 10.0.1.9:30080 check
sudo systemctl restart haproxy
sudo systemctl status haproxy

```
![haproxy  configuration](https://github.com/rukevweubio/Kubernates-multicluster-setup-Haproxy-Azurecloud/blob/main/photo/Screenshot%20(2732).png)

![haproxy  configuration](https://github.com/rukevweubio/Kubernates-multicluster-setup-Haproxy-Azurecloud/blob/main/photo/Screenshot%20(2733).png)
