#!/bin/bash

set -e #exit on error
ros_setup=on
username=$(whoami)

if test -n "$ros_setup"; then 

    # Define fancy colors
    MA='\033[0;35m'   # Magenta
    CY='\033[0;36m'      # Cyan
    OR='\033[38;5;214m' # Orange
    NC='\033[0m'           # No Color
    YE='\033[0;33m' # Yellow

    echo -e $YE
    echo "*************************************************************************"
    echo "***********************     Setting up ros_ws      **********************"
    echo "*************************************************************************"
    echo -e $NC
    
    script_path=$(dirname $(realpath $0))
    source "${script_path}/versions"
    ros_src="/home/${username}/ros_ws/src"
    ros_ws="/home/${username}/ros_ws"

    mkdir -p ${ros_src}
    sudo chown -R ${username}:${username} ${ros_ws}

    packages=(
        "ros-${ros_distro}-image-transport"
        "ros-${ros_distro}-compressed-image-transport"
    )
 
    # Start installation process
    for package in "${packages[@]}"; do
        echo -e "${MA}Installing: $package...${NC}"
        if DEBIAN_FRONTEND=noninteractive sudo apt install -y $package; then
            echo -e "${CY} Successfully installed: $package${NC}"
        else
            echo -e "${OR} Warning: Failed to install $package${NC}"
        fi
    done


    source /opt/ros/${ros_distro}/setup.bash

    cd ${ros_ws}
    colcon build --symlink-install

    # Cloning ros tutorial packages into the src directory
    cd ${ros_src}
    git clone https://github.com/ros/ros_tutorials.git
    cd ros_tutorials/

    # Moving to our specific ros distributuion's branch
    git checkout ${ros_distro}

    # Building all packages from our ros workspace's root directory
    cd ${ros_ws}
    colcon build --symlink-install

    # Sourcing our local ws packages so they're accessible system wide:
    source ${ros_ws}/install/local_setup.bash

    cd /home/${username}/



   
    echo -e $YE
    echo "*************************************************************************"
    echo "***********************      ros_ws done     ***********************"
    echo "*************************************************************************"
    echo -e $NC
fi




