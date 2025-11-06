# Quick Reference Card

## Essential Commands

### Setup and Deployment

```bash
# 1. Download packages (online machine)
ansible-playbook download-packages.yml

# 2. Configure inventory
cp inventory/hosts.example inventory/hosts
vi inventory/hosts

# 3. Configure variables
vi group_vars/all.yml

# 4. Test connectivity
ansible -i inventory/hosts all -m ping

# 5. Deploy cluster
ansible-playbook -i inventory/hosts site.yml

# 6. Verify cluster
ansible-playbook -i inventory/hosts verify-cluster.yml
```

### Using Helper Script

```bash
./setup.sh check      # Check prerequisites
./setup.sh download   # Download packages
./setup.sh inventory  # Create inventory
./setup.sh deploy     # Deploy cluster
./setup.sh verify     # Verify cluster
./setup.sh reset      # Reset cluster
```

### Cluster Management (on master)

```bash
# View nodes
kubectl get nodes

# View all pods
kubectl get pods --all-namespaces

# View cluster info
kubectl cluster-info

# Create deployment
kubectl create deployment nginx --image=nginx

# Scale deployment
kubectl scale deployment nginx --replicas=3

# Expose service
kubectl expose deployment nginx --port=80 --type=NodePort

# Delete deployment
kubectl delete deployment nginx
```

### Troubleshooting Commands

```bash
# Check services
systemctl status containerd
systemctl status kubelet

# View logs
journalctl -u containerd -f
journalctl -u kubelet -f

# Check pod logs
kubectl logs <pod-name> -n <namespace>

# Describe resources
kubectl describe node <node-name>
kubectl describe pod <pod-name> -n <namespace>

# Container runtime
crictl pods
crictl images
crictl ps

# Network debugging
kubectl run debug --image=busybox -it --rm -- /bin/sh
```

## File Locations

| Item | Path |
|------|------|
| Kubernetes config | /etc/kubernetes/admin.conf |
| Kubelet config | /var/lib/kubelet/config.yaml |
| Containerd config | /etc/containerd/config.toml |
| CNI config | /etc/cni/net.d/ |
| Offline packages | /opt/k8s-packages/ |

## Common Variables

```yaml
# In group_vars/all.yml
kubernetes_version: "1.28.0"
cni_plugin: "calico"  # or "flannel"
pod_network_cidr: "10.244.0.0/16"
api_server_advertise_address: ""  # Master IP
selinux_state: "disabled"
firewalld_state: "stopped"
```

## Port Reference

### Master Node
- 6443: API Server
- 2379-2380: etcd
- 10250: kubelet
- 10259: scheduler
- 10257: controller-manager

### Worker Node
- 10250: kubelet
- 30000-32767: NodePort

### CNI (Calico)
- 179: BGP
- 4789: VXLAN

## Directory Structure

```
k8s-offline-setup/
├── download-packages.yml   # Download playbook
├── site.yml               # Main deployment
├── reset-cluster.yml      # Cluster reset
├── verify-cluster.yml     # Health check
├── setup.sh              # Helper script
├── ansible.cfg           # Ansible config
├── group_vars/all.yml    # Variables
├── inventory/hosts       # Your inventory
└── roles/                # Ansible roles
    ├── offline-packages/
    ├── prerequisites/
    ├── container-runtime/
    ├── kubernetes/
    ├── cluster-init/
    ├── cluster-join/
    └── cni-plugin/
```

## Quick Fixes

### Node Not Ready
```bash
systemctl restart kubelet
kubectl describe node <node-name>
```

### Pods Not Starting
```bash
kubectl describe pod <pod-name> -n <namespace>
journalctl -u containerd -f
```

### DNS Issues
```bash
kubectl get pods -n kube-system | grep coredns
kubectl rollout restart deployment/coredns -n kube-system
```

### Reset Everything
```bash
ansible-playbook -i inventory/hosts reset-cluster.yml
```

## Getting Help

1. Check logs: `journalctl -u kubelet -f`
2. Describe resources: `kubectl describe`
3. Check documentation: See TROUBLESHOOTING.md
4. Enable verbose: `ansible-playbook -vvv`
5. Open GitHub issue

## Useful Links

- Repository: https://github.com/amitbansal26/k8s-offline-setup
- Kubernetes Docs: https://kubernetes.io/docs/
- Containerd Docs: https://containerd.io/docs/
- Calico Docs: https://docs.projectcalico.org/
