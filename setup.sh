#!/bin/bash

# Air-gapped Kubernetes Setup Helper Script
# This script helps prepare and deploy Kubernetes in an air-gapped environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_TAR="${PACKAGES_TAR:-k8s-packages.tar.gz}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check for Ansible
    if ! command -v ansible &> /dev/null; then
        print_error "Ansible is not installed. Please install Ansible 2.9 or higher."
        exit 1
    fi
    
    # Check Ansible version
    ANSIBLE_VERSION=$(ansible --version | head -n1 | awk '{print $2}')
    print_info "Found Ansible version: $ANSIBLE_VERSION"
    
    # Check for Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 is not installed."
        exit 1
    fi
    
    print_info "Prerequisites check passed!"
}

download_packages() {
    print_info "Starting package download..."
    print_warn "This requires internet access and may take some time."
    
    if [ ! -f "download-packages.yml" ]; then
        print_error "download-packages.yml not found!"
        exit 1
    fi
    
    ansible-playbook download-packages.yml
    
    print_info "Package download completed!"
}

setup_inventory() {
    print_info "Setting up inventory..."
    
    if [ ! -f "inventory/hosts" ]; then
        if [ -f "inventory/hosts.example" ]; then
            cp inventory/hosts.example inventory/hosts
            print_info "Created inventory/hosts from example. Please edit it with your node details."
            print_warn "Edit inventory/hosts and add your master and worker node details."
            exit 0
        else
            print_error "inventory/hosts.example not found!"
            exit 1
        fi
    else
        print_info "inventory/hosts already exists."
    fi
}

deploy_cluster() {
    print_info "Starting Kubernetes cluster deployment..."
    
    if [ ! -f "inventory/hosts" ]; then
        print_error "inventory/hosts not found! Run './setup.sh inventory' first."
        exit 1
    fi
    
    # Check if we can reach the hosts
    print_info "Testing connectivity to hosts..."
    if ! ansible -i inventory/hosts all -m ping; then
        print_error "Cannot reach all hosts. Please check your inventory and SSH access."
        exit 1
    fi
    
    print_info "Deploying Kubernetes cluster..."
    ansible-playbook -i inventory/hosts site.yml
    
    print_info "Deployment completed!"
}

verify_cluster() {
    print_info "Verifying cluster health..."
    
    if [ ! -f "verify-cluster.yml" ]; then
        print_error "verify-cluster.yml not found!"
        exit 1
    fi
    
    ansible-playbook -i inventory/hosts verify-cluster.yml
}

reset_cluster() {
    print_warn "This will completely reset the Kubernetes cluster!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Reset cancelled."
        exit 0
    fi
    
    print_info "Resetting cluster..."
    ansible-playbook -i inventory/hosts reset-cluster.yml
    
    print_info "Cluster reset completed!"
}

show_usage() {
    cat << EOF
Usage: $0 [command]

Commands:
    check       - Check prerequisites (Ansible, Python)
    download    - Download required packages (requires internet)
    inventory   - Create inventory file from example
    deploy      - Deploy Kubernetes cluster
    verify      - Verify cluster health
    reset       - Reset Kubernetes cluster
    all         - Run download and deploy (for online environments)
    help        - Show this help message

Examples:
    # On a machine with internet access:
    $0 download

    # In air-gapped environment:
    $0 inventory     # Edit inventory/hosts after this
    $0 deploy
    $0 verify

EOF
}

# Main script
case "${1:-help}" in
    check)
        check_prerequisites
        ;;
    download)
        check_prerequisites
        download_packages
        ;;
    inventory)
        setup_inventory
        ;;
    deploy)
        check_prerequisites
        deploy_cluster
        ;;
    verify)
        check_prerequisites
        verify_cluster
        ;;
    reset)
        check_prerequisites
        reset_cluster
        ;;
    all)
        check_prerequisites
        download_packages
        deploy_cluster
        verify_cluster
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
