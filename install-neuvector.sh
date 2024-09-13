#!/bin/bash

set -e
G="\e[32m"
E="\e[0m"

if [ -z "$1" ]
  then
    echo -----------------------------------------------
    echo -e "Please provide your desired Rancher DNS name as part of the install command. eg: ./install.sh rancher.mydomain.tld."
    echo -----------------------------------------------
    exit 1
fi

if ! grep -q 'Ubuntu' /etc/issue
  then
    echo -----------------------------------------------
    echo "Not Ubuntu? Could not find Codename Ubuntu in lsb_release -a. Please switch to Ubuntu."
    echo -----------------------------------------------
    exit 1
fi

## Update OS
echo "Updating OS packages..."
sudo apt update > /dev/null
sudo apt upgrade -y > /dev/null

## Install Prereqs
echo "Installing Prereqs..."
sudo apt-get update > /dev/null
sudo apt-get install -y \
apt-transport-https ca-certificates curl gnupg lsb-release \
software-properties-common haveged bash-completion  > /dev/null

## Install Helm
echo "Installing Helm..."
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3  > /dev/null
chmod 700 get_helm.sh  > /dev/null
./get_helm.sh  > /dev/null
rm ./get_helm.sh  > /dev/null


## Install K3s
echo "Installing K3s..."
sudo curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.30.4+k3s1 sh -  > /dev/null
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml  > /dev/null
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
export KUBECONFIG=~/.kube/config  > /dev/null

## Wait for K3s to come online
echo "Waiting for K3s to come online...."
sleep 5
until [ $(kubectl get nodes|grep Ready | wc -l) = 1 ]; do echo -n "." ; sleep 10; done  > /dev/null

## Install Longhorn
echo "Deploying Longhorn on K3s..."
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' > /dev/null
helm repo add longhorn https://charts.longhorn.io > /dev/null
helm repo update > /dev/null
helm upgrade --install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace > /dev/null

## Wait for Longhorn
echo "Waiting for Longhorn deployment to finish..."
until [ $(kubectl -n longhorn-system rollout status deploy/longhorn-ui|grep successfully | wc -l) = 1 ]; do echo -n "." ; sleep 2; done > /dev/null

## Install Neuvector
echo "Deploying Neuvector on K3s..."
helm repo add neuvector https://neuvector.github.io/neuvector-helm/ > /dev/null
helm repo update > /dev/null
helm upgrade --install neuvector --namespace neuvector neuvector/core -f ./values.yaml --create-namespace > /dev/null

## Wait for Neuvector
echo "Waiting for Neuvector to come online..."
until [ $(kubectl -n neuvector rollout status deploy/neuvector-manager-pod|grep successfully | wc -l) = 1 ]; do echo -n "." ; sleep 2; done > /dev/null
until [ $(kubectl -n neuvector rollout status deploy/neuvector-scanner-pod|grep successfully | wc -l) = 1 ]; do echo -n "." ; sleep 2; done > /dev/null
until [ $(kubectl -n neuvector rollout status deploy/neuvector-controller-pod|grep successfully | wc -l) = 1 ]; do echo -n "." ; sleep 2; done > /dev/null

## Print Neuvector WebUI Link (Nodeport)
NODE_PORT=$(kubectl get --namespace neuvector -o jsonpath="{.spec.ports[0].nodePort}" services neuvector-service-webui) > /dev/null
NODE_IP=$(kubectl get nodes --namespace neuvector -o jsonpath="{.items[0].status.addresses[0].address}") > /dev/null
export NEUVECTORUI=https://$NODE_IP:$NODE_PORT > /dev/null

## Install Cert-Manager
# Install the CustomResourceDefinition resources separately
echo "Deploying cert-manager on K3s..."
# kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.crds.yaml > /dev/null

# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io > /dev/null

# Update your local Helm chart repository cache
helm repo update > /dev/null

# Install the cert-manager Helm chart
helm upgrade --install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set installCRDs=true \
  --create-namespace  > /dev/null

## Wait for cert-manager
echo "Waiting for cert-manager deployment to finish..."
until [ $(kubectl -n cert-manager rollout status deploy/cert-manager|grep successfully | wc -l) = 1 ]; do echo -n "." ; sleep 2; done > /dev/null

## Install Rancher
echo "Deploying Rancher on K3s..."
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable > /dev/null
helm upgrade --install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=$1 \
  --create-namespace > /dev/null

## Wait for Rancher
echo "Waiting for Rancher UI to come online...."
until [ $(kubectl -n cattle-system rollout status deploy/rancher|grep successfully | wc -l) = 1 ]; do echo -n "." ; sleep 2; done > /dev/null

## Get Rancher Password
echo "Exporting Rancher UI password..."
export RANCHERPW=$(kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{ .data.bootstrapPassword|base64decode}}{{ "\n" }}') > /dev/null

## Print Server Information and Links
touch ./server-details.txt
echo -----------------------------------------------
echo -e ${G}Install is complete. Please use the below information to access your environment.${E} | tee ./server-details.txt
echo -e ${G}Please update your DNS or Hosts file to point https://$1 to the IP of this server $NODE_IP.${E} | tee -a ./server-details.txt
echo -e ${G}Neuvector UI:${E} $NEUVECTORUI | tee -a ./server-details.txt
echo -e ${G}Neuvector Login:${E} admin/admin \(please change the default password immediately\) | tee -a ./server-details.txt
echo -e ${G}Rancher UI:${E} https://$1 | tee -a ./server-details.txt
echo -e ${G}Rancher Password:${E} $RANCHERPW | tee -a ./server-details.txt
echo -e ${G}Kubeconfig File:${E} /etc/rancher/k3s/k3s.yaml | tee -a ./server-details.txt
echo Details above are saved to the file at ./server-details.txt
echo -----------------------------------------------
