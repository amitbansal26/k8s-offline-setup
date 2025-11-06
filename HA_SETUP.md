# High Availability Setup Guide

This guide provides detailed instructions for deploying a highly available Kubernetes cluster using HAProxy and Keepalived.

## Architecture Overview

```
                    Virtual IP (VIP)
                    192.168.56.100:6443
                           |
              +------------+------------+
              |                         |
         HAProxy + Keepalived      HAProxy + Keepalived
              (LB1)                     (LB2)
              |                         |
    +---------+---------+---------------+---------+
    |                   |                         |
Master1 (10)        Master2 (11)             Master3 (12)
    |                   |                         |
    +-------------------+-------------------------+
                        |
              +---------+---------+
              |         |         |
          Worker1    Worker2   Worker3-5
           (20)       (21)     (22-24)
```

## Components

### Load Balancer Nodes (2)
- **HAProxy**: TCP load balancer for Kubernetes API server
- **Keepalived**: VRRP daemon for VIP failover
- **Virtual IP**: 192.168.56.100 (configured in Keepalived)

### Master Nodes (3)
- Control plane components (API server, etcd, controller manager, scheduler)
- All masters are active and serve API requests through the load balancer
- Uses stacked etcd topology (etcd runs on master nodes)

### Worker Nodes (5)
- Run application workloads
- Connect to API server via the Virtual IP

## Configuration Files

### Key Configuration Files

1. **Vagrantfile**
   - Defines VM resources and network configuration
   - Creates 2 LB + 3 Master + 5 Worker nodes

2. **inventory/vagrant**
   - Ansible inventory for Vagrant environment
   - Includes loadbalancers group with VIP configuration

3. **group_vars/all.yml**
   - Global variables including `load_balancer_endpoint`

4. **roles/haproxy/**
   - HAProxy installation and configuration
   - Templates for load balancer config

5. **roles/keepalived/**
   - Keepalived installation and configuration
   - VRRP configuration for VIP management

6. **roles/cluster-init/**
   - Modified to support multi-master initialization
   - Generates join tokens for both workers and control plane

## Deployment Steps

### 1. Start Infrastructure

```bash
# Start all VMs
vagrant up

# Verify all VMs are running
vagrant status
```

### 2. Deploy Cluster

```bash
# Deploy complete HA cluster
ansible-playbook -i inventory/vagrant site.yml
```

The playbook will:
1. Configure load balancers with HAProxy and Keepalived
2. Set up prerequisites on all nodes
3. Install container runtime and Kubernetes
4. Initialize first master node
5. Join additional master nodes
6. Join worker nodes
7. Install CNI plugin

### 3. Verify Deployment

```bash
# SSH to first master
vagrant ssh k8s-master1

# Check all nodes
kubectl get nodes -o wide

# Check VIP ownership
vagrant ssh k8s-lb1
ip addr show eth1 | grep 192.168.56.100

# Check HAProxy status
vagrant ssh k8s-lb1
sudo systemctl status haproxy
sudo systemctl status keepalived

# View HAProxy stats
# Open browser: http://192.168.56.5:8404/stats
# Credentials: admin/admin
```

## High Availability Features

### API Server Load Balancing
- HAProxy distributes API requests across all 3 master nodes
- Round-robin load balancing with health checks
- Automatic removal of failed masters from pool

### Virtual IP Failover
- Keepalived maintains a Virtual IP (192.168.56.100)
- If primary LB fails, VIP moves to backup LB
- Transparent failover with minimal disruption

### etcd Quorum
- 3-node etcd cluster provides fault tolerance
- Can tolerate 1 node failure while maintaining quorum
- Data is replicated across all master nodes

## Testing HA

### Test API Server Load Balancing

```bash
# Access API via VIP
kubectl --server=https://192.168.56.100:6443 get nodes

# Check which master is handling requests (repeat multiple times)
for i in {1..10}; do
  kubectl --server=https://192.168.56.100:6443 get nodes --v=6 2>&1 | grep "GET https://"
done
```

### Test VIP Failover

```bash
# Check which LB has the VIP
vagrant ssh k8s-lb1 -c "ip addr show eth1 | grep 192.168.56.100"
vagrant ssh k8s-lb2 -c "ip addr show eth1 | grep 192.168.56.100"

# Stop keepalived on primary
vagrant ssh k8s-lb1 -c "sudo systemctl stop keepalived"

# Verify VIP moved to backup
vagrant ssh k8s-lb2 -c "ip addr show eth1 | grep 192.168.56.100"

# Verify API access still works
kubectl --server=https://192.168.56.100:6443 get nodes

# Restart keepalived
vagrant ssh k8s-lb1 -c "sudo systemctl start keepalived"
```

### Test Master Node Failure

```bash
# Stop a master node
vagrant halt k8s-master2

# Verify cluster still works
kubectl get nodes
kubectl get pods --all-namespaces

# Restart the master
vagrant up k8s-master2

# Verify it rejoins
kubectl get nodes
```

## Troubleshooting

### Check HAProxy Status

```bash
vagrant ssh k8s-lb1
sudo systemctl status haproxy
sudo journalctl -u haproxy -f
```

### Check Keepalived Status

```bash
vagrant ssh k8s-lb1
sudo systemctl status keepalived
sudo journalctl -u keepalived -f

# Check VRRP state
sudo cat /var/log/messages | grep VRRP
```

### Check API Server Connectivity

```bash
# Test from load balancer
vagrant ssh k8s-lb1
for i in 10 11 12; do
  echo "Testing 192.168.56.$i:6443"
  curl -k https://192.168.56.$i:6443/version
done
```

### Common Issues

**VIP not appearing:**
- Check Keepalived is running: `systemctl status keepalived`
- Verify interface name in keepalived.conf: `eth1` for Vagrant
- Check firewall allows VRRP: `firewall-cmd --list-all`

**HAProxy not forwarding:**
- Check backend servers in HAProxy config
- Verify masters are listening on port 6443
- Check HAProxy logs: `journalctl -u haproxy`

**Masters not joining:**
- Verify certificate key is valid (expires after 2 hours)
- Check join command is correct
- Verify network connectivity between nodes

## Production Considerations

### Security

1. **Change default passwords:**
   - HAProxy stats password
   - Keepalived auth_pass

2. **Enable firewall rules:**
   - Allow VRRP protocol between load balancers
   - Allow port 6443 from all nodes to load balancers
   - Allow port 6443 between master nodes

3. **Use separate etcd cluster:**
   - For production, consider external etcd cluster
   - Provides better isolation and scalability

### Scalability

1. **Additional masters:**
   - Can add more than 3 masters if needed
   - Maintain odd number for etcd quorum

2. **Additional load balancers:**
   - Can add more than 2 LBs for higher availability
   - Update Keepalived priority accordingly

3. **Worker nodes:**
   - Scale workers based on workload requirements
   - No practical limit on worker count

### Monitoring

1. **HAProxy metrics:**
   - Enable Prometheus exporter
   - Monitor backend health checks
   - Track request distribution

2. **Keepalived state:**
   - Monitor VIP transitions
   - Alert on frequent failovers

3. **Kubernetes health:**
   - Monitor API server latency
   - Track etcd cluster health
   - Monitor control plane components

## Additional Resources

- [Kubernetes HA Topology](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/)
- [HAProxy Documentation](http://www.haproxy.org/documentation.html)
- [Keepalived Documentation](https://www.keepalived.org/doc/)
- [etcd Clustering Guide](https://etcd.io/docs/v3.5/op-guide/clustering/)
