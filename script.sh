#!/bin/bash
sleep 1m

## Installing Pre-requisites
exec 3>&1 4>&2 # Log stdout to file
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/home/ec2-user/terraform.log 2>&1
# Update AL2
sudo yum install gcc make kernel-devel-$(uname -r) git -y
sudo yum update -y

## Mount the extra disk
sudo mkdir /data
sudo mkfs.xfs /dev/nvme2n1
sudo su -c "echo '/dev/nvme2n1 /data xfs defaults,nofail 1 2' >> /etc/fstab"

## Install Anaconda
# Mount /anaconda3
sudo mkfs.xfs /dev/sdb -f
sudo mkdir /anaconda3
sudo mount /dev/sdb /anaconda3
sudo chown -R ec2-user:ec2-user /anaconda3
sudo echo "UUID=$(lsblk -nr -o UUID,MOUNTPOINT | grep "/anaconda3" | cut -d ' ' -f 1) /anaconda3 xfs defaults,nofail 1 2" >> /etc/fstab
# Install Anaconda
wget https://repo.anaconda.com/archive/Anaconda3-2023.07-2-Linux-x86_64.sh -O /home/ec2-user/anaconda.sh &&
    bash /home/ec2-user/anaconda.sh -u -b -p /anaconda3 &&
    echo 'export PATH="/anaconda3/bin:$PATH"' >> /home/ec2-user/.bashrc &&
    rm -rf /home/ec2-user/anaconda.sh &&

## Configure Jupyter Notebook
# Configure Jupyter for AWS HTTP
runuser -l ec2-user -c 'jupyter notebook --generate-config'
# Fetch the public hostname
public_hostname=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
# Update the Jupyter Notebook config file
config_file="/home/ec2-user/.jupyter/jupyter_notebook_config.py"
# Add new lines to the end of the file
sudo echo "c.NotebookApp.ip = '$public_hostname'" >> "$config_file"
sudo echo "c.NotebookApp.allow_origin = '*'" >> "$config_file"
sudo echo "c.NotebookApp.open_browser = False" >> "$config_file"

## Install Conda Tensorflow, Torch and Nvidia CUNN
/anaconda3/bin/activate && conda init
sudo /anaconda3/bin/conda install -c conda-forge tensorflow -y
sudo /anaconda3/bin/conda install -c conda-forge langchain -y
sudo /anaconda3/bin/conda install -c pytorch -c nvidia faiss-gpu=1.8.0 -y
sudo /anaconda3/bin/conda install pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia -y
source activate base && python3 -m pip install nvidia-cudnn-cu11==8.6.0.163 tensorflow==2.13.* cmake lit

## Test Jupyter-Notebook and Prepare for Usage
nvidia-smi > /home/ec2-user/nvidia-smi
wget https://raw.githubusercontent.com/rcarrat-AI/nvidia-odh-gitops/main/templates/demo/gpu-check.ipynb -O /home/ec2-user/gpu-check.ipynb
sudo touch /home/ec2-user/usage.sh && sudo chmod u+x /home/ec2-user/usage.sh
echo "/anaconda3/bin/activate \
  && source activate base; \
  python3 -m pip install nvidia-cudnn-cu11==8.6.0.163 tensorflow==2.13.* cmake lit \
  && kind export kubeconfig --name k8s;
  docker exec -ti k8s-control-plane ln -s /sbin/ldconfig /sbin/ldconfig.real || true \
  && kubectl delete --all pod -n gpu-operator && sleep 100 && kubectl logs cuda-vectoradd >> /tmp/ec2-user/kind-gpu" > /home/ec2-user/usage.sh

## Install Kind,  Kubectl and Helm
# Kind
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
sudo chmod 775 ./kind
sudo mv ./kind /usr/local/bin/kind
# Kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
# Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
sudo chmod 700 get_helm.sh
bash get_helm.sh
# k9s
wget https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_Linux_amd64.tar.gz && tar -xzvf k9s_Linux_amd64.tar.gz
sudo chmod u+x k9s && sudo mv /home/ec2-user/k9s /usr/local/bin/k9s

## Add GPU Support
## https://github.com/kubernetes-sigs/kind/pull/3257#issuecomment-1607287275
wget https://raw.githubusercontent.com/substratusai/substratus/main/install/kind/up-gpu.sh
sudo nvidia-ctk runtime configure --runtime=docker --set-as-default
sudo systemctl restart docker
sudo sed -i '/accept-nvidia-visible-devices-as-volume-mounts/c\accept-nvidia-visible-devices-as-volume-mounts = true' /etc/nvidia-container-runtime/config.toml

## Deploy Kind Cluster with GPUs
CLUSTER_NAME="k8s"
cat <<EOF | kind create cluster --name $CLUSTER_NAME --wait 200s --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  extraMounts:
    - hostPath: /dev/null
      containerPath: /var/run/nvidia-container-devices/all
EOF
kind export kubeconfig --name k8s

## Workaround for GPU support in KIND
## https://github.com/kubernetes-sigs/kind/pull/3257#issuecomment-1607287275

# The nvidia operator needs the below symlink
# https://github.com/NVIDIA/nvidia-docker/issues/614#issuecomment-423991632
docker exec -ti k8s-control-plane ln -s /sbin/ldconfig /sbin/ldconfig.real

## Add Nvidia GPU Operator
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia || true
helm repo update
helm install --wait --generate-name \
     -n gpu-operator --create-namespace \
     nvidia/gpu-operator --set driver.enabled=false

## Deploy NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml

## Deploy Pod to Check nvidia-smi
sleep 200
kubectl apply -f - << EOF
apiVersion: v1
kind: Pod
metadata:
  name: cuda-vectoradd
spec:
  restartPolicy: OnFailure
  containers:
  - name: cuda-vectoradd
    image: "nvcr.io/nvidia/k8s/cuda-sample:vectoradd-cuda11.7.1-ubuntu20.04"
    resources:
      limits:
        nvidia.com/gpu: 1
EOF

## Sometimes GPU Operator doesn't work because of the ldconfig
bash -x /home/ec2-user/usage.sh
sleep 80
#docker exec -ti k8s-control-plane ln -s /sbin/ldconfig /sbin/ldconfig.real
#kubectl delete --all pod -n gpu-operator

sleep 20
echo "done!"
