# Troubleshooting Guide

## Common Issues and Solutions

### 1. Package Download Issues

#### Issue: "Cannot download packages - no internet connection"
**Solution:**
- Ensure you're running the download playbook on a machine with internet access
- Check your proxy settings if behind a corporate firewall
- Verify DNS resolution: `ping pkgs.k8s.io`

#### Issue: "yumdownloader command not found"
**Solution:**
```bash
sudo yum install -y yum-utils
```

### 2. SSH Connection Issues

#### Issue: "Permission denied (publickey)"
**Solution:**
- Ensure SSH key-based authentication is set up
- Copy your SSH key to target nodes:
```bash
ssh-copy-id root@<node-ip>
```
- Or configure password authentication in `ansible.cfg`:
```ini
[defaults]
host_key_checking = False
ask_pass = True
```

#### Issue: "Host key verification failed"
**Solution:**
```bash
# Remove old host key
ssh-keygen -R <node-ip>
# Or disable host key checking (less secure)
export ANSIBLE_HOST_KEY_CHECKING=False
```

### 3. SELinux Issues

#### Issue: "SELinux is preventing operation"
**Solution:**
```bash
# Temporarily disable
sudo setenforce 0

# Permanently disable
sudo sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
sudo reboot
```

### 4. Firewall Issues

#### Issue: "Connection refused on port 6443"
**Solution:**
```bash
# Stop firewalld
sudo systemctl stop firewalld
sudo systemctl disable firewalld

# Or configure firewall rules (preferred for production)
sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --permanent --add-port=2379-2380/tcp
sudo firewall-cmd --permanent --add-port=10250/tcp
sudo firewall-cmd --permanent --add-port=10251/tcp
sudo firewall-cmd --permanent --add-port=10252/tcp
sudo firewall-cmd --reload
```

### 5. Swap Issues

#### Issue: "Kubelet fails to start due to swap"
**Solution:**
```bash
# Disable swap immediately
sudo swapoff -a

# Disable swap permanently
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

### 6. Container Runtime Issues

#### Issue: "containerd not responding"
**Solution:**
```bash
# Check containerd status
sudo systemctl status containerd

# Restart containerd
sudo systemctl restart containerd

# Check logs
sudo journalctl -u containerd -n 50

# Verify socket exists
ls -la /run/containerd/containerd.sock
```

#### Issue: "Failed to create containerd config"
**Solution:**
```bash
# Manually create config
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Enable systemd cgroup driver
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Restart containerd
sudo systemctl restart containerd
```

### 7. Kubernetes Initialization Issues

#### Issue: "kubeadm init fails with timeout"
**Solution:**
```bash
# Reset kubeadm
sudo kubeadm reset -f

# Check network connectivity
ping 8.8.8.8

# Verify containerd is running
sudo systemctl status containerd

# Check for port conflicts
sudo ss -tlnp | grep 6443

# Re-run initialization with verbose output
sudo kubeadm init --v=5
```

#### Issue: "Error: unable to upgrade connection: pod not found"
**Solution:**
```bash
# Verify kubelet is running
sudo systemctl status kubelet

# Check kubelet logs
sudo journalctl -u kubelet -n 100

# Restart kubelet
sudo systemctl restart kubelet
```

### 8. Node Join Issues

#### Issue: "Worker node fails to join cluster"
**Solution:**
```bash
# On master, regenerate join command
kubeadm token create --print-join-command

# Verify network connectivity from worker to master
ping <master-ip>
telnet <master-ip> 6443

# Reset worker node
sudo kubeadm reset -f

# Try joining again with the new token
```

#### Issue: "Error: token has expired"
**Solution:**
```bash
# On master, create new token
kubeadm token create --print-join-command

# Use the new command on worker nodes
```

### 9. CNI Plugin Issues

#### Issue: "Pods stuck in ContainerCreating state"
**Solution:**
```bash
# Check CNI plugin pods
kubectl get pods -n kube-system | grep -E 'calico|flannel'

# Verify CNI configuration
ls -la /etc/cni/net.d/

# Check for errors
kubectl describe pod <pod-name> -n kube-system

# Restart CNI pods
kubectl delete pod -n kube-system -l k8s-app=calico-node
# or for flannel
kubectl delete pod -n kube-flannel -l app=flannel
```

#### Issue: "Calico pods not starting"
**Solution:**
```bash
# Check if IP autodetection is working
kubectl set env daemonset/calico-node -n kube-system IP_AUTODETECTION_METHOD=interface=eth0

# Verify CIDR configuration matches
kubectl get configmap -n kube-system calico-config -o yaml
```

### 10. DNS Issues

#### Issue: "CoreDNS pods in CrashLoopBackOff"
**Solution:**
```bash
# Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# Common fix: disable SELinux or configure properly
sudo setenforce 0

# Restart CoreDNS
kubectl rollout restart deployment/coredns -n kube-system
```

### 11. Package Installation Issues

#### Issue: "RPM installation conflicts"
**Solution:**
```bash
# Force reinstall
cd /opt/k8s-packages/rpms
sudo rpm -Uvh --force --nodeps *.rpm

# Or install specific packages
sudo yum localinstall -y kubeadm-*.rpm kubelet-*.rpm kubectl-*.rpm
```

### 12. Image Pull Issues (Air-gapped)

#### Issue: "Failed to pull image"
**Solution:**
Since this is an air-gapped environment, you need to pre-load images:

```bash
# On a machine with internet, pull and save images
kubeadm config images pull --kubernetes-version v1.28.0
docker save -o k8s-images.tar $(docker images --format "{{.Repository}}:{{.Tag}}" | grep k8s)

# Transfer k8s-images.tar to air-gapped environment

# Load images on all nodes
ctr -n k8s.io images import k8s-images.tar
```

## Diagnostic Commands

### Check Cluster Status
```bash
# Node status
kubectl get nodes -o wide

# Pod status
kubectl get pods --all-namespaces

# Component status
kubectl get componentstatuses

# Cluster info
kubectl cluster-info
```

### Check System Services
```bash
# Containerd
systemctl status containerd
journalctl -u containerd -n 50

# Kubelet
systemctl status kubelet
journalctl -u kubelet -n 50
```

### Network Debugging
```bash
# Check routes
ip route

# Check network interfaces
ip addr

# Check iptables rules
iptables -L -n -v
iptables -t nat -L -n -v

# Test pod network
kubectl run test-pod --image=busybox --command -- sleep 3600
kubectl exec -it test-pod -- ping <another-pod-ip>
```

### Check Certificates
```bash
# Check certificate expiration
kubeadm certs check-expiration

# Renew certificates
kubeadm certs renew all
```

## Getting Help

If you encounter issues not covered here:

1. Check Kubernetes logs: `journalctl -u kubelet -f`
2. Check containerd logs: `journalctl -u containerd -f`
3. Check pod logs: `kubectl logs <pod-name> -n <namespace>`
4. Describe resources: `kubectl describe <resource> <name>`
5. Enable verbose logging: Add `--v=5` to kubectl commands
6. Open an issue on GitHub with:
   - Error messages
   - Relevant logs
   - System information (`uname -a`, `cat /etc/os-release`)
   - Ansible version (`ansible --version`)

## Best Practices for Troubleshooting

1. **Check logs first**: Most issues are explained in logs
2. **Verify prerequisites**: Ensure all requirements are met
3. **Test incrementally**: Deploy one component at a time if issues persist
4. **Document changes**: Keep track of any manual changes made
5. **Use verbose mode**: Add `-vvv` to ansible-playbook for detailed output
6. **Verify network**: Many issues are network-related in air-gapped environments
