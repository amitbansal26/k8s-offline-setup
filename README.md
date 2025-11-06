# k8s-offline-setup

Ansible scripts to setup Kubernetes in an air-gapped environment on Rocky Linux 10

## Overview

This repository contains Ansible playbooks and roles to deploy a production-ready Kubernetes cluster in an air-gapped (offline) environment on Rocky Linux 10. The setup supports both single-master and multi-master configurations with your choice of CNI plugin (Calico or Flannel).

## Features

- **Air-gapped deployment**: All required packages can be downloaded once and transferred to offline environments
- **Rocky Linux 10 support**: Optimized for Rocky Linux 10
- **Container runtime**: Uses containerd as the container runtime
- **CNI plugins**: Choose between Calico or Flannel for pod networking
- **Modular roles**: Organized into reusable Ansible roles
- **Idempotent**: Safe to run multiple times
- **Prerequisites automation**: Automatically configures SELinux, firewall, swap, and kernel parameters

## Prerequisites

### Control Node (where you run Ansible)
- Ansible 2.9 or higher
- Python 3.6 or higher
- Internet access (for downloading packages)

### Target Nodes (Rocky Linux 10 servers)
- Rocky Linux 10 (minimal installation)
- SSH access with sudo privileges
- Minimum 2 CPU cores
- Minimum 2GB RAM (4GB recommended for master nodes)
- At least 20GB disk space

## Quick Start

### Step 1: Download Required Packages (on a machine with internet access)

1. Clone this repository:
```bash
git clone https://github.com/amitbansal26/k8s-offline-setup.git
cd k8s-offline-setup
```

2. Configure variables in `group_vars/all.yml`:
```bash
# Edit the following variables as needed:
# - kubernetes_version
# - cni_plugin (calico or flannel)
# - pod_network_cidr
# - etc.
vi group_vars/all.yml
```

3. Download all required packages:
```bash
ansible-playbook download-packages.yml
```

This will create a tarball at `/tmp/k8s-packages-<version>.tar.gz` containing all required packages.

4. Transfer the tarball to your offline environment.

### Step 2: Setup Kubernetes Cluster (in air-gapped environment)

1. Extract the packages tarball:
```bash
tar -xzf k8s-packages-<version>.tar.gz -C /tmp/
```

2. Configure your inventory:
```bash
cp inventory/hosts.example inventory/hosts
vi inventory/hosts
```

Add your master and worker nodes:
```ini
[masters]
master1 ansible_host=192.168.1.10 ansible_user=root

[workers]
worker1 ansible_host=192.168.1.11 ansible_user=root
worker2 ansible_host=192.168.1.12 ansible_user=root
```

3. Update `group_vars/all.yml` with your network configuration:
```yaml
# Set the master node IP
api_server_advertise_address: "192.168.1.10"

# Adjust network CIDRs if needed
pod_network_cidr: "10.244.0.0/16"
service_cidr: "10.96.0.0/12"
```

4. Run the main playbook:
```bash
ansible-playbook -i inventory/hosts site.yml
```

### Step 3: Verify the Installation

On the master node, check cluster status:
```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

## Directory Structure

```
.
├── download-packages.yml       # Playbook to download packages offline
├── site.yml                    # Main playbook for cluster setup
├── group_vars/
│   └── all.yml                # Global variables
├── inventory/
│   └── hosts.example          # Example inventory file
└── roles/
    ├── offline-packages/      # Copy packages to target nodes
    ├── prerequisites/         # System prerequisites
    ├── container-runtime/     # Install containerd
    ├── kubernetes/           # Install Kubernetes components
    ├── cluster-init/         # Initialize master node
    ├── cluster-join/         # Join worker nodes
    └── cni-plugin/          # Install CNI plugin
```

## Configuration

### Main Variables (group_vars/all.yml)

| Variable | Default | Description |
|----------|---------|-------------|
| `kubernetes_version` | `1.28.0` | Kubernetes version to install |
| `containerd_version` | `1.7.8` | Containerd version |
| `cni_plugin` | `calico` | CNI plugin (calico or flannel) |
| `pod_network_cidr` | `10.244.0.0/16` | Pod network CIDR |
| `service_cidr` | `10.96.0.0/12` | Service network CIDR |
| `selinux_state` | `disabled` | SELinux state |
| `offline_package_dir` | `/tmp/k8s-packages` | Package directory on control machine |
| `target_package_dir` | `/opt/k8s-packages` | Package directory on target nodes |

## Advanced Configuration

### High Availability (HA) Setup

For HA setup with multiple master nodes:

1. Set up a load balancer for the API server
2. Configure the load balancer endpoint:
```yaml
load_balancer_endpoint: "loadbalancer.example.com:6443"
```

3. Add multiple masters to inventory:
```ini
[masters]
master1 ansible_host=192.168.1.10 ansible_user=root
master2 ansible_host=192.168.1.11 ansible_user=root
master3 ansible_host=192.168.1.12 ansible_user=root
```

### Changing CNI Plugin

To use Flannel instead of Calico:
```yaml
cni_plugin: "flannel"
```

Note: Flannel uses `10.244.0.0/16` by default. If you change `pod_network_cidr`, ensure compatibility.

## Troubleshooting

### Common Issues

1. **SELinux preventing operations**
   - Ensure SELinux is disabled or in permissive mode
   - Check: `getenforce`

2. **Firewall blocking traffic**
   - Ensure firewalld is stopped or configured correctly
   - Check: `systemctl status firewalld`

3. **Swap enabled**
   - Kubernetes requires swap to be disabled
   - Check: `swapon --show`

4. **Container runtime not responding**
   - Verify containerd is running: `systemctl status containerd`
   - Check socket: `ls -la /run/containerd/containerd.sock`

### Logs

Check logs for troubleshooting:
```bash
# Kubelet logs
journalctl -u kubelet -f

# Containerd logs
journalctl -u containerd -f

# Pod logs
kubectl logs <pod-name> -n <namespace>
```

## Security Considerations

- Change default network CIDRs if they conflict with your network
- Use secure methods to transfer packages to air-gapped environments
- Regularly update packages and rebuild the offline package archive
- Follow Kubernetes security best practices for production deployments
- Consider enabling SELinux in enforcing mode for production (requires additional configuration)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

## Support

For issues and questions, please open an issue in the GitHub repository.

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Rocky Linux Documentation](https://docs.rockylinux.org/)
- [Containerd Documentation](https://containerd.io/docs/)
- [Calico Documentation](https://docs.projectcalico.org/)
- [Flannel Documentation](https://github.com/flannel-io/flannel)
