# Project Summary

## k8s-offline-setup: Kubernetes Air-Gapped Setup for Rocky Linux 10

### Description
A comprehensive Ansible automation solution for deploying Kubernetes clusters in air-gapped (offline) environments on Rocky Linux 10. This project provides a complete, production-ready deployment workflow from package download to cluster verification.

### Key Features
✅ **Air-Gapped Support**: Complete offline deployment capability  
✅ **Rocky Linux 10**: Optimized for Rocky Linux 10  
✅ **Modular Design**: 7 independent Ansible roles  
✅ **Idempotent**: Safe to run multiple times  
✅ **Flexible CNI**: Choice of Calico or Flannel  
✅ **HA Ready**: Supports multi-master configurations  
✅ **Well Documented**: Comprehensive guides and examples  

### What's Included

#### Ansible Playbooks
- `download-packages.yml` - Downloads all required packages for offline use
- `site.yml` - Main deployment playbook for cluster setup
- `reset-cluster.yml` - Resets Kubernetes cluster for redeployment
- `verify-cluster.yml` - Validates cluster health and functionality

#### Ansible Roles (7 roles)
1. **offline-packages** - Distributes packages to target nodes
2. **prerequisites** - Configures system prerequisites (SELinux, swap, firewall, kernel)
3. **container-runtime** - Installs and configures containerd
4. **kubernetes** - Installs Kubernetes components (kubeadm, kubelet, kubectl)
5. **cluster-init** - Initializes master node(s)
6. **cluster-join** - Joins worker nodes to the cluster
7. **cni-plugin** - Deploys Container Network Interface plugin

#### Helper Tools
- `setup.sh` - Interactive script for simplified operations
- `ansible.cfg` - Optimized Ansible configuration
- `inventory/hosts.example` - Template for inventory configuration
- `group_vars/all.yml` - Centralized variable configuration

#### Documentation (8 guides)
- **README.md** - Overview, quick start, and installation guide
- **REQUIREMENTS.md** - Detailed system and network requirements
- **EXAMPLES.md** - Step-by-step examples for common scenarios
- **TROUBLESHOOTING.md** - Solutions to common issues
- **ARCHITECTURE.md** - Design and architecture details
- **CONTRIBUTING.md** - Guidelines for contributors
- **QUICKREF.md** - Quick reference for commands
- **CHANGELOG.md** - Version history

### Technology Stack

| Component | Version | Purpose |
|-----------|---------|---------|
| Kubernetes | 1.28.0 | Container orchestration |
| Containerd | 1.7.8 | Container runtime |
| Calico | 3.26.3 | CNI plugin (default) |
| Flannel | 0.22.3 | CNI plugin (alternative) |
| CNI Plugins | 1.3.0 | Network plugins |
| Rocky Linux | 10 | Operating system |
| Ansible | 2.9+ | Automation |

### Deployment Workflow

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1: Download (Online Machine)                          │
│   ./setup.sh download                                       │
│   → Creates: /tmp/k8s-packages-1.28.0.tar.gz               │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 2: Transfer to Air-Gapped Environment                 │
│   scp k8s-packages.tar.gz airgapped:/tmp/                  │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 3: Configure (Air-Gapped)                             │
│   cp inventory/hosts.example inventory/hosts               │
│   vi inventory/hosts  # Add your nodes                     │
│   vi group_vars/all.yml  # Customize settings              │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 4: Deploy                                              │
│   ./setup.sh deploy                                         │
│   → Deploys complete Kubernetes cluster                    │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 5: Verify                                              │
│   ./setup.sh verify                                         │
│   → Validates cluster health                               │
└─────────────────────────────────────────────────────────────┘
```

### Use Cases

✅ Enterprise environments with strict internet access policies  
✅ Secure/classified networks requiring air-gapped deployments  
✅ Edge computing locations with limited connectivity  
✅ Disaster recovery scenarios  
✅ Development/testing environments mimicking production constraints  
✅ Compliance-driven deployments (banking, government, healthcare)  

### Cluster Configurations Supported

- **Single Master + Multiple Workers** - Standard production setup
- **High Availability (HA)** - Multiple masters with load balancer
- **Single Node** - Development/testing
- **Custom Network CIDRs** - Flexible network configuration
- **Multiple CNI Options** - Calico (default) or Flannel

### System Requirements

#### Minimum Per Node
- **CPU**: 2 cores
- **RAM**: 2GB (4GB recommended)
- **Disk**: 20GB free space
- **OS**: Rocky Linux 10
- **Network**: Static IP address

#### Control Machine
- **Ansible**: 2.9 or higher
- **Python**: 3.6 or higher
- **Disk**: 5GB for packages

### Quick Start

```bash
# 1. Download packages (online)
git clone https://github.com/amitbansal26/k8s-offline-setup.git
cd k8s-offline-setup
./setup.sh download

# 2. Transfer to air-gapped environment
scp /tmp/k8s-packages-*.tar.gz user@airgapped:/tmp/

# 3. In air-gapped environment
tar -xzf /tmp/k8s-packages-*.tar.gz -C /tmp/
./setup.sh inventory  # Creates inventory/hosts
# Edit inventory/hosts with your node details

# 4. Deploy
./setup.sh deploy

# 5. Verify
./setup.sh verify
```

### Project Statistics

- **Total Files**: 25+ files
- **Ansible Roles**: 7 roles
- **Playbooks**: 4 playbooks
- **Documentation Pages**: 8 guides
- **Lines of Code**: ~2,000+ lines
- **Supported Scenarios**: 10+ examples

### File Structure

```
k8s-offline-setup/
├── Playbooks (4)
│   ├── download-packages.yml
│   ├── site.yml
│   ├── reset-cluster.yml
│   └── verify-cluster.yml
├── Roles (7)
│   ├── offline-packages/
│   ├── prerequisites/
│   ├── container-runtime/
│   ├── kubernetes/
│   ├── cluster-init/
│   ├── cluster-join/
│   └── cni-plugin/
├── Documentation (8)
│   ├── README.md
│   ├── REQUIREMENTS.md
│   ├── EXAMPLES.md
│   ├── TROUBLESHOOTING.md
│   ├── ARCHITECTURE.md
│   ├── CONTRIBUTING.md
│   ├── QUICKREF.md
│   └── CHANGELOG.md
├── Configuration
│   ├── ansible.cfg
│   ├── group_vars/all.yml
│   └── inventory/hosts.example
├── Tools
│   └── setup.sh
└── License
    └── LICENSE (MIT)
```

### Testing & Validation

✅ All YAML syntax validated  
✅ Idempotency verified  
✅ Role independence confirmed  
✅ Documentation completeness checked  
✅ Example scenarios tested  

### Future Roadmap

Planned enhancements:
- Kubernetes upgrade playbook
- Backup and restore automation
- Monitoring stack (Prometheus/Grafana)
- Logging stack (ELK/EFK)
- Storage provisioners
- Ingress controller options
- Certificate rotation automation
- ARM architecture support
- Rocky Linux 9 support

### Contributing

Contributions are welcome! See CONTRIBUTING.md for guidelines.

### License

MIT License - See LICENSE file for details.

### Support

- **Issues**: GitHub Issues
- **Documentation**: See docs/ folder
- **Examples**: See EXAMPLES.md
- **Troubleshooting**: See TROUBLESHOOTING.md

### Author

Amit Bansal (https://github.com/amitbansal26)

### Links

- **Repository**: https://github.com/amitbansal26/k8s-offline-setup
- **Issues**: https://github.com/amitbansal26/k8s-offline-setup/issues
- **Discussions**: https://github.com/amitbansal26/k8s-offline-setup/discussions

---

**Note**: This is a production-ready solution designed for enterprise air-gapped Kubernetes deployments on Rocky Linux 10.
