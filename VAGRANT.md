# Vagrant Setup Guide

This guide explains how to use Vagrant to create a local Kubernetes cluster for development, testing, and learning purposes.

## Overview

The provided Vagrantfile creates a multi-node Kubernetes cluster with:
- 3 Master nodes (k8s-master1, k8s-master2, k8s-master3) - 2 CPU, 4GB RAM each
- 5 Worker nodes (k8s-worker1 through k8s-worker5) - 2 CPU, 2GB RAM each
- Private network: 192.168.56.x
- Rocky Linux 9 (closest to Rocky Linux 10)

## Prerequisites

### Required Software

1. **VirtualBox** (6.1 or higher)
   - Download: https://www.virtualbox.org/wiki/Downloads
   - Supports Windows, macOS, and Linux

2. **Vagrant** (2.2 or higher)
   - Download: https://www.vagrantup.com/downloads
   - Supports Windows, macOS, and Linux

3. **Ansible** (2.9 or higher)
   - Required on your host machine to provision the cluster
   - Installation:
     ```bash
     # macOS
     brew install ansible
     
     # Linux (Ubuntu/Debian)
     sudo apt install ansible
     
     # Linux (RHEL/CentOS/Rocky)
     sudo yum install ansible
     
     # pip
     pip install ansible
     ```

### System Requirements

- **CPU**: 6+ cores (for 3 VMs with 2 cores each)
- **RAM**: 8GB minimum (16GB recommended)
- **Disk**: 30GB free space
- **OS**: Windows 10/11, macOS 10.15+, or Linux

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/amitbansal26/k8s-offline-setup.git
cd k8s-offline-setup
```

### 2. Start Vagrant VMs

```bash
# Start all VMs (master and workers)
vagrant up

# This will:
# - Download Rocky Linux 9 box (first time only)
# - Create 3 VMs (1 master, 2 workers)
# - Configure networking and base system
# - Takes 5-10 minutes on first run
```

### 3. Verify VMs are Running

```bash
# Check VM status
vagrant status

# Should show:
# k8s-master1    running (virtualbox)
# k8s-worker1    running (virtualbox)
# k8s-worker2    running (virtualbox)

# SSH into master node
vagrant ssh k8s-master1

# Exit VM
exit
```

### 4. Configure Inventory for Vagrant

The repository includes a pre-configured inventory file for Vagrant at `inventory/vagrant`.

Verify the SSH keys are generated:
```bash
ls -la .vagrant/machines/*/virtualbox/private_key
```

### 5. Test Ansible Connectivity

```bash
# Test connection to all VMs
ansible -i inventory/vagrant all -m ping

# Should return SUCCESS for all nodes
```

### 6. Deploy Kubernetes Cluster

Since Vagrant VMs have internet access, you can deploy directly:

```bash
# Option 1: Use online deployment (VMs have internet)
ansible-playbook -i inventory/vagrant site.yml

# Option 2: Test offline deployment workflow
# First, download packages on your host
ansible-playbook download-packages.yml

# Copy packages to a shared location accessible by VMs
# Then deploy using offline packages
ansible-playbook -i inventory/vagrant site.yml
```

### 7. Verify Cluster

```bash
# Run verification playbook
ansible-playbook -i inventory/vagrant verify-cluster.yml

# Or manually check on master node
vagrant ssh k8s-master1
kubectl get nodes
kubectl get pods --all-namespaces
```

## Customization

### Modify Cluster Size

Edit the `Vagrantfile` to change cluster configuration:

```ruby
# Number of nodes
MASTER_COUNT = 1      # Change to 3 for HA setup
WORKER_COUNT = 2      # Increase for more workers

# Resource allocation
MASTER_MEMORY = 4096  # Master node RAM
WORKER_MEMORY = 2048  # Worker node RAM
MASTER_CPU = 2        # Master node CPUs
WORKER_CPU = 2        # Worker node CPUs
```

After changes:
```bash
vagrant destroy -f
vagrant up
```

### Change Network Configuration

Edit the network prefix in `Vagrantfile`:

```ruby
NETWORK_PREFIX = "192.168.56"  # Change as needed
```

Don't forget to update `inventory/vagrant` accordingly.

### Test Different CNI Plugins

Edit `group_vars/all.yml`:

```yaml
cni_plugin: "flannel"  # Switch between calico and flannel
```

## Common Vagrant Commands

### VM Management

```bash
# Start all VMs
vagrant up

# Start specific VM
vagrant up k8s-master1

# Stop all VMs
vagrant halt

# Stop specific VM
vagrant halt k8s-worker1

# Restart all VMs
vagrant reload

# Destroy all VMs (delete)
vagrant destroy -f

# Check VM status
vagrant status

# Show global Vagrant VM status
vagrant global-status
```

### SSH Access

```bash
# SSH into master
vagrant ssh k8s-master1

# SSH into worker
vagrant ssh k8s-worker1

# Run command on VM without SSH
vagrant ssh k8s-master1 -c "kubectl get nodes"
```

### Troubleshooting

```bash
# Re-run provisioning
vagrant provision

# Re-provision specific VM
vagrant provision k8s-master1

# View VM console in VirtualBox GUI
# Useful for debugging boot issues
vagrant up
# Then open VirtualBox and double-click VM
```

## Testing Workflow

### Test Air-Gapped Deployment

1. **Download packages on host**:
   ```bash
   ansible-playbook download-packages.yml
   ```

2. **Create shared folder** in Vagrantfile:
   ```ruby
   config.vm.synced_folder ".", "/vagrant"
   ```

3. **Reload VMs**:
   ```bash
   vagrant reload
   ```

4. **Copy packages to VMs**:
   ```bash
   vagrant ssh k8s-master1
   sudo cp -r /vagrant/tmp/k8s-packages /opt/
   exit
   ```

5. **Deploy cluster**:
   ```bash
   ansible-playbook -i inventory/vagrant site.yml
   ```

### Test Cluster Reset

```bash
# Reset cluster
ansible-playbook -i inventory/vagrant reset-cluster.yml

# Redeploy
ansible-playbook -i inventory/vagrant site.yml
```

### Test HA Configuration

1. **Modify Vagrantfile**:
   ```ruby
   MASTER_COUNT = 3
   ```

2. **Recreate VMs**:
   ```bash
   vagrant destroy -f
   vagrant up
   ```

3. **Update inventory/vagrant** to include all 3 masters

4. **Configure load balancer** (HAProxy on separate VM or host)

5. **Deploy HA cluster**

## Integration with Development Workflow

### Local Development

```bash
# Make changes to playbooks/roles
vim roles/prerequisites/tasks/main.yml

# Test changes immediately
ansible-playbook -i inventory/vagrant site.yml

# Iterate quickly without affecting production
```

### Testing New Features

```bash
# Create feature branch
git checkout -b feature/new-cni-plugin

# Make changes and test
vagrant destroy -f
vagrant up
ansible-playbook -i inventory/vagrant site.yml

# Verify
ansible-playbook -i inventory/vagrant verify-cluster.yml
```

## Resource Management

### Reduce Resource Usage

For development on limited hardware:

```ruby
# Vagrantfile - minimal configuration
MASTER_COUNT = 1
WORKER_COUNT = 1
MASTER_MEMORY = 2048
WORKER_MEMORY = 1536
```

### Snapshot and Restore

```bash
# Take snapshot before deployment
vagrant snapshot save baseline

# Deploy and test
ansible-playbook -i inventory/vagrant site.yml

# Restore to baseline if needed
vagrant snapshot restore baseline

# List snapshots
vagrant snapshot list

# Delete snapshot
vagrant snapshot delete baseline
```

## Performance Tips

1. **Use linked clones** (faster VM creation):
   ```ruby
   config.vm.provider "virtualbox" do |vb|
     vb.linked_clone = true
   end
   ```

2. **Allocate more resources** if available:
   ```ruby
   MASTER_MEMORY = 8192  # 8GB for master
   ```

3. **Use SSD** for VM storage

4. **Enable VT-x/AMD-V** in BIOS for hardware virtualization

## Troubleshooting

### Issue: VMs Won't Start

**Solution**:
```bash
# Check VirtualBox is running
VBoxManage list vms

# Check host resources
# Ensure you have enough RAM/CPU available

# Try destroying and recreating
vagrant destroy -f
vagrant up
```

### Issue: Network Connectivity Problems

**Solution**:
```bash
# Check VirtualBox host-only network
VBoxManage list hostonlyifs

# Recreate network if needed
vagrant destroy -f
vagrant up
```

### Issue: Ansible Can't Connect

**Solution**:
```bash
# Verify SSH keys exist
ls .vagrant/machines/*/virtualbox/private_key

# Test SSH manually
ssh -i .vagrant/machines/k8s-master1/virtualbox/private_key vagrant@192.168.56.10

# Re-provision to fix SSH
vagrant provision
```

### Issue: Slow Performance

**Solution**:
- Reduce number of VMs
- Allocate fewer resources per VM
- Close other applications
- Use snapshot/restore for faster iterations

## Cleaning Up

### Remove VMs

```bash
# Stop and delete all VMs
vagrant destroy -f

# Remove downloaded Vagrant boxes (optional)
vagrant box remove generic/rocky9
```

### Free Disk Space

```bash
# Clean up Vagrant global data
vagrant global-status --prune

# Remove old VirtualBox VMs
# Open VirtualBox GUI and remove manually
```

## Advanced Usage

### Multi-Network Setup

Test different network configurations:

```ruby
# Vagrantfile
master.vm.network "private_network", ip: "10.0.0.10", virtualbox__intnet: "k8s-internal"
master.vm.network "private_network", ip: "192.168.56.10"
```

### Custom Provisioning

Add custom provisioning scripts:

```ruby
# Vagrantfile
config.vm.provision "shell", path: "scripts/custom-setup.sh"
```

### Integration Testing

Create test scenarios:

```bash
#!/bin/bash
# test-deployment.sh

vagrant destroy -f
vagrant up
ansible-playbook -i inventory/vagrant site.yml
ansible-playbook -i inventory/vagrant verify-cluster.yml
```

## Next Steps

After setting up your Vagrant environment:

1. Familiarize yourself with the cluster
2. Deploy sample applications
3. Test backup and restore procedures
4. Experiment with different configurations
5. Contribute improvements back to the project

## Resources

- **Vagrant Documentation**: https://www.vagrantup.com/docs
- **VirtualBox Documentation**: https://www.virtualbox.org/wiki/Documentation
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Rocky Linux**: https://rockylinux.org/

## Support

For issues specific to the Vagrant setup:
1. Check this guide's troubleshooting section
2. Open an issue on GitHub
3. Consult Vagrant/VirtualBox documentation

---

**Note**: Vagrant setup is for development and testing only. For production deployments, use bare metal or cloud infrastructure as described in the main README.md.
