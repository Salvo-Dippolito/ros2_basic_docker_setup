ARG ros_distro

# Full ROS image with gazebo and Rviz
FROM osrf/ros:${ros_distro}-desktop

ARG ros_distro=humble

SHELL [ "/bin/bash" ]
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV TZ Europe/Rome

COPY components/aptUpdate.sh /tmp/components/aptUpdate.sh
RUN /tmp/components/aptUpdate.sh         

##################### Components #####################
# Load component versions (changes on this file will make Docker rebuild all that follows)
COPY components/versions /tmp/components/versions

COPY components/base.sh /tmp/components/base.sh
RUN /tmp/components/base.sh

# Common path for system components installed inside scripts
ENV components_path /ros_components


##################### User Setup #####################
# Setting up user environment within the docker image
ARG username

#setting these up for userSetup.sh:

ARG uid
ARG gid 

COPY components/userSetup.sh /tmp/components/userSetup.sh
RUN /tmp/components/userSetup.sh
USER ${username}
ENV PATH "$PATH:/usr/local/bin"
ENV HOME /home/${username}
WORKDIR /home/${username}

# Configure tmux user environment
COPY target_bin/tmux.conf /home/${username}/.tmux.conf


# Load scripts to build a ros workspace after user setup:

COPY components/versions /home/${username}/wss_setup/versions
COPY components/ros_setup.sh /home/${username}/wss_setup/ros_setup.sh
