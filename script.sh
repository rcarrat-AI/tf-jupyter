#!/bin/bash
sleep 1m
# Log stdout to file
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/home/ec2-user/terraform.log 2>&1
# Update AL2
sudo yum install gcc make kernel-devel-$(uname -r) git -y
sudo yum update -y
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



wget https://raw.githubusercontent.com/rcarrat-AI/nvidia-odh-gitops/main/templates/demo/gpu-check.ipynb -O /home/ec2-user/gpu-check.ipynb

/anaconda3/bin/activate && conda init
sudo /anaconda3/bin/conda install -c conda-forge tensorflow -y
sudo /anaconda3/bin/conda install pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia -y
python3 -m pip install nvidia-cudnn-cu11==8.6.0.163 tensorflow==2.13.*
# pip install tensorflow 
# pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Test that works
nvidia-smi > /home/ec2-user/nvidia-smi
echo "/anaconda3/bin/activate && source activate base" > /home/ec2-user/usage
echo "done!"