# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-11-06

### Added
- Initial release of k8s-offline-setup
- Complete Ansible automation for air-gapped Kubernetes deployment on Rocky Linux 10
- Download playbook for offline package preparation
- Main site playbook for cluster deployment
- Seven modular roles:
  - offline-packages: Package distribution
  - prerequisites: System preparation
  - container-runtime: Containerd installation
  - kubernetes: K8s component installation
  - cluster-init: Master node initialization
  - cluster-join: Worker node joining
  - cni-plugin: CNI plugin deployment (Calico/Flannel)
- Reset playbook for cluster cleanup
- Verify playbook for health checks
- Helper script (setup.sh) for simplified operations
- Comprehensive documentation:
  - README.md: Overview and quick start
  - REQUIREMENTS.md: System requirements
  - EXAMPLES.md: Usage examples
  - TROUBLESHOOTING.md: Common issues and solutions
  - ARCHITECTURE.md: Design and architecture details
  - CONTRIBUTING.md: Contribution guidelines
- Configuration files:
  - ansible.cfg: Ansible configuration
  - group_vars/all.yml: Global variables
  - inventory/hosts.example: Inventory template
- Support for Kubernetes 1.28.0
- Support for Containerd 1.7.8
- Support for Calico v3.26.3 and Flannel v0.22.3
- MIT License

### Features
- Air-gapped deployment support
- Rocky Linux 10 optimized
- Idempotent playbooks
- Single-master and HA configurations
- Configurable CNI plugins (Calico or Flannel)
- Automated prerequisites configuration
- Service status verification
- Test deployment capability

### Documentation
- Quick start guide
- Step-by-step examples for common scenarios
- Comprehensive troubleshooting guide
- Architecture and design documentation
- System requirements documentation
- Contributing guidelines

## [Unreleased]

### Changed
- Updated to Kubernetes 1.31.2 (latest stable version)
- Updated Containerd to 1.7.22
- Updated Calico to v3.28.2
- Updated Flannel to v0.25.7

### Added
- Vagrant setup for local development and testing
- VAGRANT.md: Comprehensive Vagrant documentation
- Vagrantfile: Multi-node cluster configuration
- inventory/vagrant: Pre-configured Vagrant inventory
- Local testing workflow support

### Planned
- Kubernetes upgrade playbook
- Backup and restore automation
- Monitoring stack integration (Prometheus/Grafana)
- Logging stack integration (ELK/EFK)
- Storage provisioner options
- Ingress controller installation
- Certificate rotation automation
- ARM architecture support
- Rocky Linux 9 support
- Additional CNI plugin options

[1.0.0]: https://github.com/amitbansal26/k8s-offline-setup/releases/tag/v1.0.0
