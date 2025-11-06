# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrant setup for local Kubernetes cluster testing
# This creates a multi-node Kubernetes cluster using Rocky Linux 10

# Cluster configuration
MASTER_COUNT = 3
WORKER_COUNT = 5
LOADBALANCER_COUNT = 2
MASTER_CPU = 2
MASTER_MEMORY = 4096
WORKER_CPU = 2
WORKER_MEMORY = 2048
LOADBALANCER_CPU = 1
LOADBALANCER_MEMORY = 1024
NETWORK_PREFIX = "192.168.56"
LOADBALANCER_IP_START = 5
MASTER_IP_START = 10
WORKER_IP_START = 20

Vagrant.configure("2") do |config|
  # Base box configuration
  config.vm.box = "generic/rocky9"  # Rocky 10 not yet available, using Rocky 9 as closest
  config.vm.box_check_update = false

  # Disable default synced folder
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # Load balancer nodes (HAProxy + Keepalived)
  (1..LOADBALANCER_COUNT).each do |i|
    config.vm.define "k8s-lb#{i}" do |lb|
      lb.vm.hostname = "k8s-lb#{i}"
      lb.vm.network "private_network", ip: "#{NETWORK_PREFIX}.#{LOADBALANCER_IP_START + i - 1}"
      
      lb.vm.provider "virtualbox" do |vb|
        vb.name = "k8s-lb#{i}"
        vb.memory = LOADBALANCER_MEMORY
        vb.cpus = LOADBALANCER_CPU
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
      end

      # Provisioning script
      lb.vm.provision "shell", inline: <<-SHELL
        # Update hosts file
        cat >> /etc/hosts <<EOF
#{(1..LOADBALANCER_COUNT).map { |j| "#{NETWORK_PREFIX}.#{LOADBALANCER_IP_START + j - 1} k8s-lb#{j}" }.join("\n")}
#{(1..MASTER_COUNT).map { |j| "#{NETWORK_PREFIX}.#{MASTER_IP_START + j - 1} k8s-master#{j}" }.join("\n")}
#{(1..WORKER_COUNT).map { |j| "#{NETWORK_PREFIX}.#{WORKER_IP_START + j - 1} k8s-worker#{j}" }.join("\n")}
EOF

        # Disable SELinux
        setenforce 0 2>/dev/null || true
        sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

        # Disable swap
        swapoff -a
        sed -i '/ swap / s/^/#/' /etc/fstab

        # Stop firewall
        systemctl stop firewalld 2>/dev/null || true
        systemctl disable firewalld 2>/dev/null || true

        # Install basic tools
        yum install -y vim curl wget git
      SHELL
    end
  end

  # Master nodes
  (1..MASTER_COUNT).each do |i|
    config.vm.define "k8s-master#{i}" do |master|
      master.vm.hostname = "k8s-master#{i}"
      master.vm.network "private_network", ip: "#{NETWORK_PREFIX}.#{MASTER_IP_START + i - 1}"
      
      master.vm.provider "virtualbox" do |vb|
        vb.name = "k8s-master#{i}"
        vb.memory = MASTER_MEMORY
        vb.cpus = MASTER_CPU
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
      end

      # Provisioning script
      master.vm.provision "shell", inline: <<-SHELL
        # Update hosts file
        cat >> /etc/hosts <<EOF
#{(1..LOADBALANCER_COUNT).map { |j| "#{NETWORK_PREFIX}.#{LOADBALANCER_IP_START + j - 1} k8s-lb#{j}" }.join("\n")}
#{(1..MASTER_COUNT).map { |j| "#{NETWORK_PREFIX}.#{MASTER_IP_START + j - 1} k8s-master#{j}" }.join("\n")}
#{(1..WORKER_COUNT).map { |j| "#{NETWORK_PREFIX}.#{WORKER_IP_START + j - 1} k8s-worker#{j}" }.join("\n")}
EOF

        # Disable SELinux
        setenforce 0 2>/dev/null || true
        sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

        # Disable swap
        swapoff -a
        sed -i '/ swap / s/^/#/' /etc/fstab

        # Stop firewall
        systemctl stop firewalld 2>/dev/null || true
        systemctl disable firewalld 2>/dev/null || true

        # Load kernel modules
        modprobe overlay
        modprobe br_netfilter

        # Configure sysctl
        cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
        sysctl --system

        # Install basic tools
        yum install -y vim curl wget git
      SHELL
    end
  end

  # Worker nodes
  (1..WORKER_COUNT).each do |i|
    config.vm.define "k8s-worker#{i}" do |worker|
      worker.vm.hostname = "k8s-worker#{i}"
      worker.vm.network "private_network", ip: "#{NETWORK_PREFIX}.#{WORKER_IP_START + i - 1}"
      
      worker.vm.provider "virtualbox" do |vb|
        vb.name = "k8s-worker#{i}"
        vb.memory = WORKER_MEMORY
        vb.cpus = WORKER_CPU
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
      end

      # Provisioning script
      worker.vm.provision "shell", inline: <<-SHELL
        # Update hosts file
        cat >> /etc/hosts <<EOF
#{(1..LOADBALANCER_COUNT).map { |j| "#{NETWORK_PREFIX}.#{LOADBALANCER_IP_START + j - 1} k8s-lb#{j}" }.join("\n")}
#{(1..MASTER_COUNT).map { |j| "#{NETWORK_PREFIX}.#{MASTER_IP_START + j - 1} k8s-master#{j}" }.join("\n")}
#{(1..WORKER_COUNT).map { |j| "#{NETWORK_PREFIX}.#{WORKER_IP_START + j - 1} k8s-worker#{j}" }.join("\n")}
EOF

        # Disable SELinux
        setenforce 0 2>/dev/null || true
        sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

        # Disable swap
        swapoff -a
        sed -i '/ swap / s/^/#/' /etc/fstab

        # Stop firewall
        systemctl stop firewalld 2>/dev/null || true
        systemctl disable firewalld 2>/dev/null || true

        # Load kernel modules
        modprobe overlay
        modprobe br_netfilter

        # Configure sysctl
        cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
        sysctl --system

        # Install basic tools
        yum install -y vim curl wget git
      SHELL
    end
  end
end
