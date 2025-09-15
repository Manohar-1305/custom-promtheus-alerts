#!/bin/bash
sudo apt update -y
apt  install docker.io -y
sudo apt update -y && sudo apt upgrade -y

snap install helm --classic
sudo snap install kubectl --classic

curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/

cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30000
        hostPort: 30000
      - containerPort: 30001
        hostPort: 30001
      - containerPort: 30002
        hostPort: 30002
      - containerPort: 30003
        hostPort: 30003
      - containerPort: 30004
        hostPort: 30004
      - containerPort: 30005
        hostPort: 30005
  - role: worker
  - role: worker
EOF

sudo chmod 644 kind-config.yaml
sudo chown $USER:$USER kind-config.yaml

sudo kind create cluster --name my-cluster --config kind-config.yaml
