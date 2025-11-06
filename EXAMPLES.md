# Quick Start Examples

This guide provides step-by-step examples for common deployment scenarios.

## Scenario 1: Simple Single-Master Cluster

### Environment
- 1 Master node: 192.168.1.10
- 2 Worker nodes: 192.168.1.11, 192.168.1.12
- Rocky Linux 10 on all nodes

### Steps

#### 1. Download Packages (on internet-connected machine)

```bash
# Clone the repository
git clone https://github.com/amitbansal26/k8s-offline-setup.git
cd k8s-offline-setup

# Run download playbook
ansible-playbook download-packages.yml

# Package will be created at /tmp/k8s-packages-1.28.0.tar.gz
```

#### 2. Transfer to Air-Gapped Environment

```bash
# Copy the tarball to your air-gapped environment
scp /tmp/k8s-packages-1.28.0.tar.gz user@airgapped-machine:/tmp/

# On the air-gapped machine, extract
tar -xzf /tmp/k8s-packages-1.28.0.tar.gz -C /tmp/
```

#### 3. Configure Inventory

```bash
# Copy example inventory
cp inventory/hosts.example inventory/hosts

# Edit inventory file
vi inventory/hosts
```

Add your nodes:
```ini
[masters]
k8s-master ansible_host=192.168.1.10 ansible_user=root

[workers]
k8s-worker1 ansible_host=192.168.1.11 ansible_user=root
k8s-worker2 ansible_host=192.168.1.12 ansible_user=root

[k8s_cluster:children]
masters
workers

[k8s_cluster:vars]
ansible_python_interpreter=/usr/bin/python3
```

#### 4. Configure Variables

Edit `group_vars/all.yml`:
```yaml
api_server_advertise_address: "192.168.1.10"
pod_network_cidr: "10.244.0.0/16"
service_cidr: "10.96.0.0/12"
cni_plugin: "calico"
```

#### 5. Deploy Cluster

```bash
# Test connectivity
ansible -i inventory/hosts all -m ping

# Deploy
ansible-playbook -i inventory/hosts site.yml

# This will take 10-15 minutes
```

#### 6. Verify Installation

```bash
# Run verification
ansible-playbook -i inventory/hosts verify-cluster.yml

# Or manually on master node
ssh root@192.168.1.10
kubectl get nodes
kubectl get pods --all-namespaces
```

---

## Scenario 2: High-Availability (HA) Cluster

### Environment
- 3 Master nodes: 192.168.1.10-12
- 3 Worker nodes: 192.168.1.13-15
- Load Balancer: 192.168.1.100 (HAProxy or similar)

### Additional Configuration

#### 1. Set Up Load Balancer First

Configure HAProxy to load balance on port 6443:
```
frontend kubernetes-frontend
    bind 192.168.1.100:6443
    mode tcp
    option tcplog
    default_backend kubernetes-backend

backend kubernetes-backend
    mode tcp
    balance roundrobin
    option tcp-check
    server master1 192.168.1.10:6443 check fall 3 rise 2
    server master2 192.168.1.11:6443 check fall 3 rise 2
    server master3 192.168.1.12:6443 check fall 3 rise 2
```

#### 2. Update Inventory

```ini
[masters]
k8s-master1 ansible_host=192.168.1.10 ansible_user=root
k8s-master2 ansible_host=192.168.1.11 ansible_user=root
k8s-master3 ansible_host=192.168.1.12 ansible_user=root

[workers]
k8s-worker1 ansible_host=192.168.1.13 ansible_user=root
k8s-worker2 ansible_host=192.168.1.14 ansible_user=root
k8s-worker3 ansible_host=192.168.1.15 ansible_user=root
```

#### 3. Update Variables

```yaml
load_balancer_endpoint: "192.168.1.100:6443"
api_server_advertise_address: "192.168.1.10"  # First master's IP
```

#### 4. Deploy

```bash
ansible-playbook -i inventory/hosts site.yml
```

---

## Scenario 3: Using Flannel Instead of Calico

### Configuration

Edit `group_vars/all.yml`:
```yaml
cni_plugin: "flannel"
pod_network_cidr: "10.244.0.0/16"  # Flannel's default
```

### Deploy

```bash
ansible-playbook -i inventory/hosts site.yml
```

---

## Scenario 4: Custom Kubernetes Version

### Configuration

Edit `group_vars/all.yml`:
```yaml
kubernetes_version: "1.27.0"
kubernetes_version_rhel_package: "1.27.0"
```

### Download Specific Version

```bash
# Update download playbook variables
ansible-playbook download-packages.yml
```

---

## Scenario 5: Re-deploying After Failure

If something goes wrong during deployment:

```bash
# Reset the cluster
ansible-playbook -i inventory/hosts reset-cluster.yml

# Fix the issue (check logs, update configuration)

# Deploy again
ansible-playbook -i inventory/hosts site.yml
```

---

## Scenario 6: Adding Worker Nodes Later

### Steps

#### 1. Add new worker to inventory

```ini
[workers]
k8s-worker1 ansible_host=192.168.1.11 ansible_user=root
k8s-worker2 ansible_host=192.168.1.12 ansible_user=root
k8s-worker3 ansible_host=192.168.1.13 ansible_user=root  # New node
```

#### 2. Run playbook only for new node

```bash
ansible-playbook -i inventory/hosts site.yml --limit k8s-worker3
```

---

## Scenario 7: Using SSH Key Authentication

### Setup

```bash
# Generate SSH key if you don't have one
ssh-keygen -t rsa -b 4096

# Copy key to all nodes
for ip in 192.168.1.{10..15}; do
    ssh-copy-id root@$ip
done

# Test connectivity
ansible -i inventory/hosts all -m ping
```

---

## Scenario 8: Using Non-Root User

### Configuration

Update inventory:
```ini
[masters]
k8s-master ansible_host=192.168.1.10 ansible_user=admin

[workers]
k8s-worker1 ansible_host=192.168.1.11 ansible_user=admin

[k8s_cluster:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_become=yes
ansible_become_method=sudo
```

Ensure the user has sudo privileges without password:
```bash
# On each node, add to /etc/sudoers
admin ALL=(ALL) NOPASSWD: ALL
```

---

## Scenario 9: Customizing Package Download Location

### Configuration

Edit `group_vars/all.yml`:
```yaml
offline_package_dir: "/home/myuser/k8s-packages"
target_package_dir: "/opt/kubernetes/packages"
```

Download:
```bash
ansible-playbook download-packages.yml
```

---

## Scenario 10: Running Specific Roles Only

### Examples

```bash
# Only install prerequisites
ansible-playbook -i inventory/hosts site.yml --tags prerequisites

# Only install container runtime
ansible-playbook -i inventory/hosts site.yml --tags container-runtime

# Skip package copy (if already done)
ansible-playbook -i inventory/hosts site.yml --skip-tags offline-packages
```

Note: Tags need to be added to tasks in roles for this to work.

---

## Post-Installation Tasks

### 1. Configure kubectl on Your Local Machine

```bash
# Copy config from master
scp root@192.168.1.10:/etc/kubernetes/admin.conf ~/.kube/config

# Test
kubectl get nodes
```

### 2. Deploy Sample Application

```yaml
# nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

```bash
kubectl apply -f nginx-deployment.yaml
kubectl get deployments
kubectl get pods
```

### 3. Set Up Storage (Optional)

Install local storage provisioner or NFS provisioner based on your needs.

---

## Helper Script Usage

The `setup.sh` script provides shortcuts:

```bash
# Check prerequisites
./setup.sh check

# Download packages
./setup.sh download

# Create inventory from example
./setup.sh inventory

# Deploy cluster
./setup.sh deploy

# Verify cluster
./setup.sh verify

# Reset cluster
./setup.sh reset

# All-in-one (download + deploy + verify)
./setup.sh all
```

---

## Tips

1. **Always test connectivity first**: `ansible -i inventory/hosts all -m ping`
2. **Use verbose mode for debugging**: Add `-vvv` to ansible-playbook
3. **Check logs if something fails**: `journalctl -u kubelet -f`
4. **Verify prerequisites**: Use the verify playbook regularly
5. **Keep backups**: Save your `/etc/kubernetes/` directory regularly
