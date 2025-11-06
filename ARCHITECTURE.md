# Architecture and Design

## Overview

This project implements a complete air-gapped Kubernetes deployment solution for Rocky Linux 10 using Ansible automation. The design focuses on modularity, idempotency, and ease of use.

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Control Machine                          │
│              (with Internet Access)                         │
│  ┌────────────────────────────────────────────────────┐    │
│  │  1. Download Packages (download-packages.yml)      │    │
│  │     - Kubernetes binaries                          │    │
│  │     - Containerd runtime                           │    │
│  │     - CNI plugins                                  │    │
│  │     - Dependencies (RPM packages)                  │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ Transfer packages
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              Air-Gapped Environment                         │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │              Master Node(s)                           │ │
│  │  ┌─────────────────────────────────────────────┐     │ │
│  │  │  - API Server (port 6443)                   │     │ │
│  │  │  - etcd                                      │     │ │
│  │  │  - Controller Manager                        │     │ │
│  │  │  - Scheduler                                 │     │ │
│  │  │  - kubelet                                   │     │ │
│  │  │  - CNI Plugin (Calico/Flannel)              │     │ │
│  │  └─────────────────────────────────────────────┘     │ │
│  └───────────────────────────────────────────────────────┘ │
│                           │                                 │
│                           │ Pod Network                     │
│                           │                                 │
│  ┌───────────────────────────────────────────────────────┐ │
│  │              Worker Node(s)                           │ │
│  │  ┌─────────────────────────────────────────────┐     │ │
│  │  │  - kubelet                                   │     │ │
│  │  │  - kube-proxy                               │     │ │
│  │  │  - Container Runtime (containerd)            │     │ │
│  │  │  - CNI Plugin                               │     │ │
│  │  └─────────────────────────────────────────────┘     │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Deployment Flow

### Phase 1: Package Download (Online)

```
download-packages.yml
    │
    ├─> Add Kubernetes repository
    ├─> Download Kubernetes RPMs (kubeadm, kubelet, kubectl)
    ├─> Download container runtime (containerd)
    ├─> Download CNI plugins
    ├─> Download CNI manifests (Calico/Flannel)
    ├─> Download dependencies
    └─> Create tarball
```

### Phase 2: Cluster Deployment (Offline)

```
site.yml
    │
    ├─> offline-packages (all nodes)
    │   └─> Copy packages to target nodes
    │
    ├─> prerequisites (all nodes)
    │   ├─> Disable SELinux
    │   ├─> Disable swap
    │   ├─> Configure firewall
    │   ├─> Load kernel modules
    │   └─> Configure sysctl parameters
    │
    ├─> container-runtime (all nodes)
    │   ├─> Install containerd
    │   ├─> Install runc
    │   ├─> Install CNI plugins
    │   ├─> Configure containerd
    │   └─> Start containerd service
    │
    ├─> kubernetes (all nodes)
    │   ├─> Install kubeadm, kubelet, kubectl
    │   ├─> Configure kubelet
    │   └─> Start kubelet service
    │
    ├─> cluster-init (master nodes)
    │   ├─> Initialize Kubernetes cluster
    │   ├─> Configure kubectl
    │   └─> Generate join token
    │
    ├─> cluster-join (worker nodes)
    │   └─> Join worker nodes to cluster
    │
    └─> cni-plugin (first master)
        └─> Deploy CNI plugin (Calico or Flannel)
```

## Role Descriptions

### 1. offline-packages
**Purpose**: Transfer downloaded packages to target nodes  
**Tasks**:
- Create package directory
- Copy packages via synchronize
- Verify package integrity

### 2. prerequisites
**Purpose**: Prepare system for Kubernetes  
**Tasks**:
- Disable SELinux (configurable)
- Disable swap
- Stop/disable firewalld (configurable)
- Load required kernel modules (overlay, br_netfilter)
- Configure sysctl parameters for networking
- Install base packages (iproute-tc, socat, etc.)

### 3. container-runtime
**Purpose**: Install and configure containerd  
**Tasks**:
- Extract and install containerd binaries
- Install runc
- Install CNI plugins
- Create containerd systemd service
- Generate default containerd config
- Configure systemd cgroup driver
- Start and enable containerd

### 4. kubernetes
**Purpose**: Install Kubernetes components  
**Tasks**:
- Install kubeadm, kubelet, kubectl from RPMs
- Configure crictl for containerd
- Enable kubelet service

### 5. cluster-init
**Purpose**: Initialize Kubernetes master  
**Tasks**:
- Check if already initialized
- Run kubeadm init with proper parameters
- Configure kubectl for root user
- Generate join command for workers
- Save join command for distribution

### 6. cluster-join
**Purpose**: Join worker nodes to cluster  
**Tasks**:
- Check if node already joined
- Copy join command from controller
- Execute join command
- Clean up join command file

### 7. cni-plugin
**Purpose**: Install Container Network Interface plugin  
**Tasks**:
- Deploy Calico or Flannel manifests
- Modify pod CIDR if needed
- Wait for CNI pods to be ready
- Verify all pods are running

## Network Configuration

### Default Network Ranges

| Network | CIDR | Purpose |
|---------|------|---------|
| Pod Network | 10.244.0.0/16 | Pod-to-pod communication |
| Service Network | 10.96.0.0/12 | Service ClusterIPs |

### Required Ports

**Master Node**:
- 6443: Kubernetes API server
- 2379-2380: etcd server
- 10250: kubelet API
- 10259: kube-scheduler
- 10257: kube-controller-manager

**Worker Node**:
- 10250: kubelet API
- 30000-32767: NodePort services

**CNI Plugin** (Calico):
- 179: BGP
- 4789: VXLAN (optional)

**CNI Plugin** (Flannel):
- 8285: flannel overlay
- 8472: flannel VXLAN

## Configuration Management

### Variable Hierarchy

```
group_vars/all.yml (global defaults)
    │
    ├─> Kubernetes versions
    ├─> Container runtime settings
    ├─> Network configuration
    ├─> CNI plugin selection
    ├─> Security settings (SELinux, firewall)
    └─> Path configurations
```

### Key Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| kubernetes_version | K8s version to install | 1.28.0 |
| containerd_version | Containerd version | 1.7.8 |
| cni_plugin | CNI plugin choice | calico |
| pod_network_cidr | Pod network range | 10.244.0.0/16 |
| service_cidr | Service network range | 10.96.0.0/12 |
| selinux_state | SELinux state | disabled |

## Idempotency Design

All tasks are designed to be idempotent:

1. **Check before action**: Use `stat`, `shell` with conditions
2. **Creates parameter**: For file extraction, downloads
3. **State management**: Use `state: present/absent`
4. **Conditional execution**: Use `when` clauses extensively
5. **Registration**: Store task results for conditional logic

Example:
```yaml
- name: Check if Kubernetes is already initialized
  stat:
    path: /etc/kubernetes/admin.conf
  register: k8s_initialized

- name: Initialize Kubernetes cluster
  shell: kubeadm init ...
  when: not k8s_initialized.stat.exists
```

## High Availability Considerations

For HA setup:

1. **Multiple master nodes**: Deploy 3 or 5 master nodes
2. **Load balancer**: External LB for API server (HAProxy/Nginx)
3. **Stacked etcd**: etcd runs on master nodes
4. **Join additional masters**: Use `--control-plane` flag

## Security Considerations

### Implemented
- Systemd cgroup driver for containerd
- Kernel module loading for networking
- Sysctl parameters for bridge networking
- Service isolation via systemd

### Configurable
- SELinux state (disabled/permissive/enforcing)
- Firewall state (stopped/configured)

### Recommended for Production
- Enable SELinux with proper policies
- Configure firewall with specific rules
- Use secrets management (Vault, etc.)
- Enable RBAC
- Network policies
- Pod Security Standards

## Offline Package Management

### Package Types

1. **RPM Packages**:
   - Kubernetes components (kubeadm, kubelet, kubectl)
   - Dependencies (socat, conntrack, etc.)

2. **Binary Archives**:
   - Containerd tarball
   - runc binary
   - CNI plugins tarball

3. **Manifests**:
   - Calico YAML
   - Flannel YAML

### Transfer Methods

1. Physical media (USB drive)
2. Secure file transfer
3. Private package repository

## Maintenance and Updates

### Updating Kubernetes Version

1. Update `group_vars/all.yml`
2. Download new packages
3. Transfer to air-gapped environment
4. Run upgrade playbook (to be created)

### Adding Nodes

Run site.yml with `--limit` for specific nodes

### Removing Nodes

1. Drain node: `kubectl drain <node>`
2. Delete node: `kubectl delete node <node>`
3. Run reset playbook on the node

## Testing Strategy

### Validation Points

1. **Pre-deployment**: Prerequisites check
2. **During deployment**: Service status checks
3. **Post-deployment**: Cluster verification
4. **Continuous**: Health monitoring

### Verification Playbook

The `verify-cluster.yml` playbook checks:
- Node status
- Pod status
- Component health
- Service availability
- Test deployment capability

## Troubleshooting Approach

### Layered Debugging

1. **Ansible level**: `-vvv` flag, check connectivity
2. **System level**: Service status, logs
3. **Kubernetes level**: kubectl commands, pod logs
4. **Network level**: Connectivity tests, DNS resolution
5. **Container level**: crictl commands, containerd logs

### Log Locations

- Ansible: stdout, `/var/log/ansible.log` (if configured)
- Containerd: `journalctl -u containerd`
- Kubelet: `journalctl -u kubelet`
- Pods: `kubectl logs`

## Extension Points

The architecture supports:

1. **Custom roles**: Add new roles to `roles/` directory
2. **Additional playbooks**: Create specialized playbooks
3. **Variable overrides**: Use inventory variables
4. **Tags**: Add tags to tasks for selective execution
5. **Hooks**: Pre/post task hooks via Ansible

## Performance Considerations

### Optimization Techniques

1. **Pipelining**: Enabled in ansible.cfg
2. **Fact caching**: JSON file caching configured
3. **Parallel execution**: Ansible's default fork=5
4. **Package caching**: Local package directory

### Resource Requirements

Minimum per node:
- CPU: 2 cores
- RAM: 2GB (4GB recommended)
- Disk: 20GB
- Network: 1Gbps recommended

## Future Enhancements

Potential additions:

1. Kubernetes upgrade playbook
2. Backup and restore playbooks
3. Monitoring stack installation (Prometheus, Grafana)
4. Logging stack (ELK/EFK)
5. Service mesh (Istio/Linkerd)
6. Storage provisioners
7. Ingress controller
8. Certificate rotation automation
9. Multi-CNI support
10. ARM architecture support
