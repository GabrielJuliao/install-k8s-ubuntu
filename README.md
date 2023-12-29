# Kubernetes Setup Script (Ubuntu)

This script automates the installation and configuration of Kubernetes on Ubuntu systems. It installs essential components like container runtimes (containerd), network interfaces, and sets up a Kubernetes control plane.

## Prerequisites
- **Ubuntu** (20.04 - 22.04): This script is intended for Ubuntu systems.
- **Root Access**: Ensure you have root privileges to execute the script.
- **Unique Hostname**: Make sure each node has a unique hostname for cluster identification.
- **Static IP Address**: Configure a static IP address for each node in the cluster.

## Steps

1. **Clone Repository**:
   ```bash
   git clone https://github.com/GabrielJuliao/install-k8s-ubuntu.git
   ```

2. **Network Configuration**:
   - Configure Static IP:
     - Use the file `00-installer-config.yaml` or create a new one based on the provided template.
     - The YAML file (`netplan-config.yaml`) contains network configuration settings for setting up a static IP using Netplan.
     
     ```yaml
     network:
       version: 2
       renderer: networkd
       ethernets:
         enp0s3:
           addresses:
             - 192.168.1.100/24
           routes:
             - to: 0.0.0.0/0
               via: 192.168.1.1
               on-link: true
           nameservers:
             addresses: [1.1.1.1, 8.8.8.8]
     ```

     **Explanation**:
      - `network`: Top-level key specifying network configuration.
      - `version: 2`: Netplan configuration version.
      - `renderer: networkd`: Backend renderer used.
      - `ethernets`: Configuration for Ethernet interfaces.
      - `enp0s3`: Interface name. Replace with your actual interface name (you can list them by  using the command `ip a`).
      - `addresses`: Specifies static IP address and subnet mask.
      - `routes`: Defines routing information including the default route and gateway IP.
      - `nameservers`: Specifies DNS server settings.
     
     **Test/Apply configuration**
     - Edit the file to set the desired static IP address, subnet mask, gateway, and DNS server IPs for your node.
     - Place the file under `/etc/netplan`.
     - Test the configuration using `netplan try` (Note: SSH connections may disrupt).
     - Apply the configuration permanently using `netplan apply`.

   - Configure Hostname:
     - Use `hostnamectl set-hostname NEW_HOSTNAME` to set a new hostname.
     - Replace `NEW_HOSTNAME` with the desired hostname.
     - Verify the change by running `hostname`.

   **NOTE**: Ensure that the IP addresses provided, both for static assignment and the hostname, are either leased from your network's DHCP server or are outside the DHCP range to prevent conflicts or address allocation issues within your network.

3. **Versions**:
   - Modify variables at the top of the script to specify Kubernetes, containerd, CNI, and network versions as needed.

4. **Run the Script**:
   ```bash
   sudo ./install.sh
   ```

5. **Initialize Control Plane**:
   - After running the script, it will prompt to initialize a control plane if desired.
   - Follow post-installation instructions provided by the script after initializing the control plane.

## Configuration Variables

You can configure the versions of the installed packeges by changing the variables at the beginning of the script (`install.sh`).

- `KUBERNETES_VERSION`: Version of Kubernetes to install.
- `CONTAINERD_VERSION`: Version of containerd (container runtime).
- `RUNC_VERSION`: Version of runc (container runtime dependency).
- `CNI_VERSION`: Version of CNI (Container Network Interface).
- `POD_NETWORK_CIDR`: Pod network CIDR for Kubernetes cluster.
- `WEAVE_NETWORK_VERSION`: Version of Weave Network to be installed.

## Script Details

- **Network Configuration**:
  - Initializes necessary network configurations for Kubernetes.
  - Modifies system settings and configurations related to networking.

- **Install Containerd**:
  - Downloads and installs containerd, container runtime, and related dependencies.
  - Configures containerd and its services.

- **Install Kubernetes**:
  - Disables swap, sets up Kubernetes repositories, and installs required Kubernetes components (`kubelet`, `kubeadm`, `kubectl`).

- **Initialize Control Plane**:
  - Prompts the user to initialize a control plane.
  - Initializes Kubernetes control plane and provides additional instructions for setting up worker nodes and running workloads.

## Important Notes

- Ensure you review and modify variables according to your system requirements before running the script.
- Follow post-installation instructions provided by the script after initializing the control plane.
