# Rocky Linux 10 - Kubernetes Air-Gapped Setup

## System Requirements

### Hardware Requirements (per node)

#### Master Node
- **CPU**: Minimum 2 cores (4 cores recommended)
- **RAM**: Minimum 2GB (4GB recommended, 8GB for production)
- **Disk**: Minimum 20GB free space (50GB recommended)
- **Network**: Static IP address

#### Worker Node
- **CPU**: Minimum 2 cores
- **RAM**: Minimum 2GB (4GB recommended based on workload)
- **Disk**: Minimum 20GB free space
- **Network**: Static IP address

### Software Requirements

#### Control Machine (with internet access)
- Operating System: Any Linux distribution or macOS
- Ansible: 2.9 or higher
- Python: 3.6 or higher
- Disk space: 5GB for downloaded packages

#### Target Nodes (air-gapped)
- Operating System: Rocky Linux 10
- SSH server running and accessible
- User with sudo privileges

## Network Requirements

### Required Ports (Master Node)

| Protocol | Port Range | Purpose |
|----------|------------|---------|
| TCP | 6443 | Kubernetes API server |
| TCP | 2379-2380 | etcd server client API |
| TCP | 10250 | Kubelet API |
| TCP | 10259 | kube-scheduler |
| TCP | 10257 | kube-controller-manager |

### Required Ports (Worker Nodes)

| Protocol | Port Range | Purpose |
|----------|------------|---------|
| TCP | 10250 | Kubelet API |
| TCP | 30000-32767 | NodePort Services |

### CNI Plugin Ports

#### Calico
| Protocol | Port | Purpose |
|----------|------|---------|
| TCP | 179 | BGP |
| UDP | 4789 | VXLAN (if using) |

#### Flannel
| Protocol | Port | Purpose |
|----------|------|---------|
| UDP | 8285 | flannel overlay |
| UDP | 8472 | flannel VXLAN |

## Pre-Installation Checklist

- [ ] All nodes have static IP addresses
- [ ] All nodes have unique hostnames
- [ ] All nodes can resolve each other's hostnames (via /etc/hosts or DNS)
- [ ] SSH key-based authentication is configured from control machine to all nodes
- [ ] User has sudo privileges on all nodes
- [ ] Minimum hardware requirements are met
- [ ] Required ports are open (or firewall is disabled)
- [ ] SELinux is set to permissive or disabled
- [ ] Swap is disabled on all nodes

## Package Versions

This setup uses the following versions by default (configurable in `group_vars/all.yml`):

- **Kubernetes**: 1.28.0
- **Containerd**: 1.7.8
- **CNI Plugins**: 1.3.0
- **Calico**: 3.26.3
- **Flannel**: 0.22.3

## Tested Environments

This playbook has been designed for:
- Rocky Linux 10
- Air-gapped/offline environments
- Both single-master and multi-master configurations

## Additional Notes

### Swap
Kubernetes requires swap to be disabled. The playbook automatically disables swap.

### SELinux
For production environments, it's recommended to configure SELinux in enforcing mode with appropriate policies. This playbook sets it to disabled by default for simplicity. To use enforcing mode, additional SELinux policies may be required.

### Firewall
The playbook disables firewalld by default. For production environments, configure firewall rules to allow only required ports.

### Time Synchronization
Ensure all nodes have synchronized time (using NTP/chrony). Time skew can cause certificate validation issues.

### DNS
Ensure proper DNS resolution or configure /etc/hosts with all node IP addresses and hostnames.
