#!/bin/bash
sudo apt-get update && sudo apt-get install jq moreutils -y
# Add the nvidia container toolkit repository. 
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Install the nvidia container toolkit

sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit -y

# Set the runtime for the toolkit to docker

sudo nvidia-ctk runtime configure --runtime=docker




# Register GPUS with the docker engine daemon
# Get daemon configuration document
daemonConfigFile="/etc/docker/daemon.json"
daemonConfig=$(jq '.' "$daemonConfigFile")
echo "$daemonConfig"

# Add default runtime string to existing configuration if it doesn't exist
if echo "$daemonConfig" | jq 'has("default-runtime")'
then 
    defaultRuntime="{ \"default-runtime\": \"nvidia\"}"
    daemonConfig=$(echo "$daemonConfig" | jq '. |= . + '"$defaultRuntime")
fi

# Add node-generic-resources array to existing configuration if it doesn't exist
if echo "$daemonConfig" | jq 'has("node-generic-resources")'
then 
    nodeResources="{ \"node-generic-resources\": []}"
    daemonConfig=$(echo "$daemonConfig" | jq '. |= . + '"$nodeResources")
fi

# Get NVIDIA GPU ID(s)
GPU_IDS=$(nvidia-smi -a | grep UUID | awk '{print substr($4,0,12)}')
#Add the NVIDIA GPU UUIDs to the node's conifguration document as an advertised resource
while read line || [ "$line" ]; do
    GPU_ID="${line}"
    daemonConfig=$(echo "$daemonConfig" | jq '."node-generic-resources" += ["NVIDIA-GPU='"$GPU_ID"'"]')
done <<< $GPU_IDS

echo "$daemonConfig" | jq | sudo sponge $daemonConfigFile

sudo systemctl restart docker