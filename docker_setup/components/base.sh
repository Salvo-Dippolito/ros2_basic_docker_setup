#!/bin/bash
set -e
YE='\033[0;33m' # Yellow
NC='\033[0m' # No Color

echo -e $YE
echo "*************************************************************************"
echo "********************** Installing Base Components ***********************"
echo "*************************************************************************"
echo -e $NC

DEBIAN_FRONTEND=noninteractive apt update

DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends -y \
    udev \
    wget \
    curl \
    unzip \
    vim \
    lshw \
    libbabeltrace1 \
    gdb \
    libncurses-dev \
    dbus \
    dbus-x11 \
    libcanberra-gtk3-module \
    libcanberra-gtk3-0 \
    packagekit-gtk3-module \
    at-spi2-core \
    gedit \
    screen \
    lm-sensors \
    pciutils \
    python3-pip \
    terminator \
    libeigen3-dev \
    libopencv-dev \
    bash-completion \
    cmake \
    mesa-utils \
    iproute2


# Ensure python points to python3
if [ ! -e /usr/bin/python ]; then
    ln -s /usr/bin/python3 /usr/bin/python
fi


DEBIAN_FRONTEND=noninteractive apt -yq --allow-downgrades install \
    lsb-release \
    htop \
    nvtop \
    tmuxinator \
    ranger \
    tzdata \
    git \
    git-lfs \
    vim \
    tmux \
    sudo \
    dialog \
    less \
    ros-dev-tools \
    ros-${ros_distro}-vision-msgs \
    ros-${ros_distro}-rqt-common-plugins \
    libnss3 \
    libboost-thread-dev \
    python3-libtmux \
    software-properties-common \
    usbutils


rosdep update --rosdistro=${ros_distro}



echo -e $YE
echo "*************************************************************************"
echo "********************** Base Components Installed ************************"
echo "*************************************************************************"
echo -e $NC