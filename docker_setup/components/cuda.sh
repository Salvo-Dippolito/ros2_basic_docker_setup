#!/bin/bash
set -e #exit on error

if test -n "$cuda"; then #cuda has been declared in the Dockerfile with ARG cuda, this checks if the variable has been declared
    script_path=$(dirname $(realpath $0))
    source "${script_path}/versions"

    YE='\033[0;33m' # Yellow
    NC='\033[0m' # No Color
    echo -e $YE
    echo "*************************************************************************"
    echo "*********************** Installing CUDA Components **********************"
    echo "*************************************************************************"
    echo -e $NC

    # --------------------- nvidia/cudagl:11.4.2-base-ubuntu20.04 ---------------------
    # https://gitlab.com/nvidia/container-images/cuda/-/blob/85f465ea3343a2d7f7753a0a838701999ed58a01/dist/12.5.1/ubuntu2204/base/Dockerfile

    #NVARCH=x86_64 set in the versions file

    # Set up the CUDA repository
    DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
        gnupg2 curl ca-certificates
    curl -fsSLO https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/${NVARCH}/cuda-keyring_1.1-1_all.deb
    dpkg -i cuda-keyring_1.1-1_all.deb
    apt update
    echo "AAAAAAAAAA"

    DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
    cuda-cudart-${CUDA_BASE_VERSION}=${NV_CUDA_CUDART_VERSION} \
    cuda-compat-${CUDA_BASE_VERSION} 

    # Required for nvidia-docker v1
    echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf
    
    echo "BBBBBBBBBB"
    # This is setting up CUDA Toolkit 12.9 for Ubuntu 20.04, with cudacompat 
    # libraries it should be able to run with a 565 driver with cuda 12.7
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
    mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
    # wget https://developer.download.nvidia.com/compute/cuda/12.9.0/local_installers/cuda-repo-ubuntu2004-12-9-local_12.9.0-575.51.03-1_amd64.deb
    # dpkg -i cuda-repo-ubuntu2004-12-9-local_12.9.0-575.51.03-1_amd64.deb
    # cp /var/cuda-repo-ubuntu2004-12-9-local/cuda-*-keyring.gpg /usr/share/keyrings/
    # apt-get update

    echo "CCCCCCCCCC"
    wget https://developer.download.nvidia.com/compute/cuda/12.8.0/local_installers/cuda-repo-ubuntu2004-12-8-local_12.8.0-570.86.10-1_amd64.deb
    dpkg -i cuda-repo-ubuntu2004-12-8-local_12.8.0-570.86.10-1_amd64.deb
    cp /var/cuda-repo-ubuntu2004-12-8-local/cuda-*-keyring.gpg /usr/share/keyrings/
    apt-get update

    echo "DDDDDDDDDD"

    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        cuda-toolkit-${CUDA_BASE_VERSION}

    # For libraries in the cuda-compat-* package: https://docs.nvidia.com/cuda/eula/index.html#attachment-a

    # From https://docs.nvidia.com/deploy/cuda-compatibility/ we read that :
    # "The CUDA forward compatibility package is named after the highest toolkit that it can support. 
    # If you are on the 535 driver (so cuda 12.2) but require 12.5 application support, please install the CUDA compatibility package for 12.5."

    #cuda real time and cuda compatibility libraries:

    


    # ln -s cuda-11.4 /usr/local/cuda # FIXME: what was the purpose of this?




    echo -e $YE
    echo "*************************************************************************"
    echo "*********************** CUDA Components Installed ***********************"
    echo "*************************************************************************"
    echo -e $NC
fi