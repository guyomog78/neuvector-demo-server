# Neuvector Demo Server

It's a https://github.com/AlphaBravoCompany/neuvector-demo-server fork

## About Neuvector (now part of SUSE)

NeuVector Full Lifecycle Container Security Platform delivers the only cloud-native security with uncompromising end-to-end protection from DevOps vulnerability protection to automated run-time security, and featuring a true Layer 7 container firewall.

- Docs: https://open-docs.neuvector.com
- Chart: https://neuvector.github.io/neuvector-helm/
- Git Repo: https://github.com/neuvector/neuvector-helm
- Website: https://neuvector.com/

## Learn more about Neuvector

- Introducing Neuvector: https://www.youtube.com/watch?v=_PHDXvygJtU
- Neuvector 101 (Fall 2021): https://www.youtube.com/watch?v=9ihaBr_QGzQ
- Introduction to Kubernetes: Security & NeuVector: https://www.crowdcast.io/e/intro_to_k8s_SecNeu_05022022/1

## Intended usage of this script

This script is for demo purposes only. It deploys a bare minimum, single node K3s Kubernetes cluster, Longhorn Storage, and the Beta of Neuvector and provides links to the interfaces and login information.

## Prerequisites
- Ubuntu 20.04+ Server (last update OK on UBUNTU 23.10)
- Minimum Recommended 4vCPU and 8GB of RAM (Try Hetzner or DigitalOcean)
- DNS or Hosts file entry pointing to server IP

## Installed as part of script

- Helm
- K3s
- Rancher UI
- Longhorn Storage
- cert-manager
- Neuvector

## Full Server Setup with Neuvector Helm Chart

1. `git clone https://github.com/guyomog78/neuvector-demo-server.git`
2. `cd neuvector-demo-server`
3. `chmod +x install-neuvector.sh`
4. `./install-neuvector.sh subdomain.yourdomain.tld`
5. Install will take approximately 5 minutes and will output links and login information for Rancher and your Neuvector installation.
6. Details for accessing Neuvector and Rancher will be printed to the screen once the script completes and saved to `server-details.txt`

# Uninstall

1. `/usr/local/bin/k3s-uninstall.sh` (removes K3s, Rancher, Longhorn and Neuvector)
2. remove `~/.kube/config` if new test is planned

## Special Thanks

Thanks to Alphabravo for source of this script, remember, it's a fork.
