#!/bin/bash

set -e # exit on error

# INTERNAL PARAMETERS
current_dir=`pwd -P`
script_name=`basename $0` #$0 is the first positional argument of the .sh script
                          # basically the command that was used to run the script, a relative path leading to where the script is
                          # basename extracts the last bit of the path, so the script's name

script_dir="$( cd "$(dirname "$0")" ; pwd -P )" #pwd -P prints the name of the directory cd just moved to
                                                # assigning that value to the variable script_dir
# scriptdir=/home/salvo/docker_images/fast_livo/docker_setup/
ros_variant=""
ros_distro="humble${ros_variant}"
uid=$(id -u)
gid=$(id -g)

if [[ $# -ne 1 ]]; then
    echo "Error: Missing mandatory positional argument: root_workspace" >&2
    usage
    exit 1
fi
ws_root_path="$1" #relative path to a folder that acts as a workspace for ros
                  #this workspace gets mapped both on the host machine and in the docker container
                  #obtained from the image we're setting up 

echo " absolute path of the workspace: ${ws_root_abspath} since relative path given is ${ws_root_path} "

# create root workspace directory if it's not present
if [[ ! -d "${script_dir}/${ws_root_path}/ws" ]]; then
    echo "Warning: root workspace directory not found: ${script_dir}/${ws_root_path}" >&2
    mkdir -p "${script_dir}/${ws_root_path}/ws"
    echo "Not a problem, the directory was created."
fi

# create ros workspace directory in the host machine if it's not present
if [[ ! -d "${script_dir}/${ws_root_path}/ros_ws" ]]; then
    echo "Warning: ros workspace directory not found: ${script_dir}/${ws_root_path}/ros_ws" >&2
    mkdir -p "${script_dir}/${ws_root_path}/ros_ws"
    echo "Not a problem, the directory was created."
fi

# get the absolute paths of your workspace directories
ws_root_abspath=$( cd "${script_dir}/${ws_root_path}/ws" ; pwd -P ) 
ros_root_abspath=$( cd "${script_dir}/${ws_root_path}/ros_ws" ; pwd -P )


# Fetch components programmatically from the components directory, excluding UTILITY_COMPONENTS
UTILITY_COMPONENTS=(aptUpdate aptPurge base userSetup userScripts)
ADDON_MODULES=() #declare an empty array
for component in $(ls ${script_dir}/components/*.sh); do
    # list all .sh files in the /components directory 
    component_name=$(basename ${component} .sh)
    if [[ ! " ${UTILITY_COMPONENTS[@]} " =~ " ${component_name} " ]]; then
        # if the component name is not in the utility_components array then 
        # put it in the ADDON_MODULES array
        ADDON_MODULES+=(${component_name})
    fi
done

print_distros() {
    echo " These are the modules with valid installation sripts present in the /docker_setup directory: "
    echo " ${ADDON_MODULES[@]}"
}

guest_username="drone_lab" 
cname="ros2_humble" # shows up in the image tag, it's the name of the container that runs from the image we're creating
build_options=""
create_options=""
modules="" # maybe add opencv and other modules here as a list, each of these need a specific .sh script
           # with necessary installation steps to be placed in the components directory, they get called by the Dockerfile

# Parsing the module list by splitting the variable by commas
echo "Checking addon modules..."
docker_modules=""
if [[ -n "${modules}" ]]; then
    IFS=',' read -r -a module_list <<< "${modules}"
    # turns the modules string into a list, extracting single elements by reading between commas
    for module in "${module_list[@]}"; do
        if [[ ! " ${ADDON_MODULES[@]} " =~ " ${module} " ]]; then
            echo "Invalid module: ${module}" >&2; print_distros; exit 1
        else
            docker_modules+="--build-arg ${module}=true " #these get then added to the docker build command
        fi
    done
fi

echo "**************************************************************"
echo "Ready to build Docker with the following parameters:"
echo "      ROS distribution: ${ros_distro}"
echo "      Workspace root directory: ${ws_root_abspath}"
echo
echo "      Modules:          ${modules}"
echo "      Build options:    ${build_options}"
echo "      Xserver bind:     ${xserver_bindings:-true}"
echo
echo "      Container Name:   ${cname}"
echo "      Guest username:   ${guest_username}"
echo "      User  ID:         ${uid}"
echo "      Group ID:         ${gid}"
echo "**************************************************************"
echo "hit enter to continue or ctrl+c to cancel (15 seconds timeout)"
read -t 15 || echo "Timeout reached, continuing..."

############################################################################################################
# BUILDING DOCKER IMAGE FROM DOCKERFILE
############################################################################################################

# image tag may have give some additional information about the docker environment we're creating:
image_tag="${cname}_img"

DOCKER_BUILDKIT=1 docker build ${build_options} \
    --file Dockerfile \
    --build-arg ros_distro="${ros_distro}" \
    --build-arg username="${guest_username}" \
    --build-arg uid="${uid}" \
    --build-arg gid="${gid}" \
    ${docker_modules} \
    --progress=plain \
    -t "${image_tag}" \
    .

echo
echo "Docker image built successfully! Tagged as ${image_tag}"

###########################################################################################################
# CREATING DOCKER IMAGE
###########################################################################################################

if [[ -z "${ws_root_abspath}" ]]; then
    echo "No workspace directory specified, won't create the image :P ."
    exit 0
fi


if [[ -z "${ros_root_abspath}" ]]; then
    echo "No ros workspace directory specified, won't create the image :P ."
    exit 0
fi

read -p "Ready to create the container, hit enter to continue or ctrl+c to cancel" dontcare

# Get desired total memory: from the system or selected by the user?

# calculate what is 80% of the available memory:
total_memory="$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') * 80 / 100 /1024 ))M"

read -p "System total memory: ${total_memory}. Use as it is, or type the desired memory (empty for default): " user_memory

if [[ -n "${user_memory}" ]]; then
    total_memory="${user_memory}"
fi
echo "Total memory for the container: ${total_memory}"

create_options+=" --privileged "
create_options+="--memory ${total_memory} "
create_options+="--device /dev/dri:/dev/dri "
create_options+="-v /dev:/dev "
create_options+="-v /proc:/proc "
create_options+="-v /run/udev:/run/udev "
create_options+="-v /sys:/sys "
create_options+="-v /tmp:/tmp "
create_options+="--user=${guest_username} "
create_options+="-e TERM=xterm-256color "
create_options+="-v /etc/localtime:/etc/localtime:ro "
create_options+="-v ${script_dir}/target_bin:/home/${guest_username}/bin "
create_options+="-v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket "

# rosout bugfix in Archlinux
# Ref: https://answers.ros.org/question/336963/rosout-high-memory-usage/
create_options+="--ulimit nofile=1024:524288 "

#options to have docker container output graphical stuff on your host's screen
#xserver_bindings is true by default, this bit might have to be changed if we figure out how to do this for remote ssh machines
if ${xserver_bindings:-true}; then
    create_options+="-e DISPLAY=$DISPLAY "
    create_options+="-e QT_X11_NO_MITSHM=1 "
    create_options+="-v /tmp/.X11-unix:/tmp/.X11-unix:rw "
    create_options+="-v $HOME/.Xauthority:/home/${guest_username}/.Xauthority:rw "
    create_options+="-e XDG_RUNTIME_DIR=/run/user/$(id -u) "
    create_options+="-v $XDG_RUNTIME_DIR:$XDG_RUNTIME_DIR "
fi

create_options+="--network host " 
# this allows the container to use the host's network stack
# if disabled, remember to expose the inner ssh port

create_options+="--ipc host "
#this shares the host's inter process communication namespace with the docker container,
# allows different containers on the same host to communicate using shared memory

create_options+="--pid host "
#this shares the host's process namespace with the docker container,
# allows the container to see all the processes running on the host machine and viceversa



# Detect Nvidia GPU presence
echo "Checking for Nvidia GPU..."
if [[ -n `lspci | grep -i nvidia` ]]; then
    create_options+="--gpus all "
    # create_options+="--runtime=nvidia "  # alternative of `--gpus all`, usually deprecated
    # TODO: get NVIDIA_VISIBLE_DEVICES
    create_options+="-e NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES:-all} "
    create_options+="-e NVIDIA_DRIVER_CAPABILITIES=all "
    create_options+="-e __NV_PRIME_RENDER_OFFLOAD=1 "
    create_options+="-e __GLX_VENDOR_LIBRARY_NAME=nvidia "
    echo "Nvidia GPU detected. Enabling GPU support."

fi

# Parse the mount_ws_dirnames list
echo "Checking workspace directories..."
mount_ws_options=""

echo "Will mount ${ws_root_abspath} to /home/${guest_username}/ws and ${ros_root_abspath} to /home/${guest_username}/ros_ws/src"
echo 
#root workspace mount
mount_ws_options+="-v "${ws_root_abspath}":/home/${guest_username}/ws "

#ros workspace mount
mount_ws_options+="-v "${ros_root_abspath}":/home/${guest_username}/ros_ws/src "

echo "mount options: ${mount_ws_options} "
echo

container_name=$(echo ${cname} | sed 's/[^a-zA-Z0-9_-]//g')
#This ensures that container_name is a valid Docker container name, 
# since Docker names only allow letters, numbers, underscores (_), and dashes (-).


echo "Deploying to ${container_name}... "
echo

echo "Will remove old container (if present)... "
echo

docker container stop ${container_name} > /dev/null 2>&1 || true
docker container rm ${container_name} > /dev/null 2>&1 || true

echo "create a new container from this image... The command is: docker create ${create_options} \
    ${mount_ws_options} \
    --name '${container_name}' \
    -it ${image_tag}"
echo

###########################################################################################################

#DOCKER CREATE CONTAINER



docker create ${create_options} \
    ${mount_ws_options} \
    --name "${container_name}" \
    -it ${image_tag}


###########################################################################################################



#Create a shell script to run the image we made consistently
run_script_file="${ws_root_abspath}/${cname}_run.sh"
echo "Saving the command to run the container to ${run_script_file}"
if [[ -f "${run_script_file}" ]]; then
    read -p "A file with the same name already exists. Do you want to overwrite it? (Y/n): " answer
    if [[ ${answer,,} == "n" ]]; then
        echo "Nothing more to do then!"
        exit 0
    fi
else
    touch "${run_script_file}"
    echo "Run script created at ${run_script_file}"
fi


# Test again, to create the container if now does not exist
if [ "`docker ps -aqf "name=${container_name}"`" == "" ]; then
    docker create ${create_options} \
        ${mount_ws_options} \
        --name "${container_name}" \
        -it ${image_tag} > /dev/null
    echo "New container named ${container_name} created, based on image ${image_tag}."
fi

cat > ${ws_root_abspath}/${cname}_recreate_container.sh << EOL

#!/usr/bin/bash

docker create ${create_options} \\
    ${mount_ws_options} \\
    --name "${container_name}" \\
    -it ${image_tag}
EOL

# Replace DISPLAY hardcoded value with an inferred one at script runtime
sed -i "s,\(-e DISPLAY=\)[^ ]*,\1\$DISPLAY," ${ws_root_abspath}/${cname}_recreate_container.sh

echo
chmod +x ${ws_root_abspath}/${cname}_recreate_container.sh
echo "Recreate script created at ${ws_root_abspath}/${cname}_recreate_container.sh"
echo



cat > "${run_script_file}" << EOL
#!/bin/bash

current_dir=\`pwd -P\`
script_dir="\$( cd "\$(dirname "\$0")" ; pwd -P )"
# The script name, without '_run' and the extension
container_name=\$(basename "\$0" | cut -d '.' -f 1 | sed 's/_run\$//')

# Check if the container exists (even stopped)
if [ "\`docker ps -aqf "name=\${container_name}"\`" == "" ]; then
    echo "The container \${container_name} does not exist." 2>&1
    echo "Please verify and eventually rename this script with the same name as the container." 2>&1
    exit 1
fi

# Check if the container is running
if [ "\`docker ps -qf "name=\${container_name}"\`" == "" ]; then
    echo "Starting previously stopped container..."
    docker start "\${container_name}"
fi


guest_username="${guest_username}"  # <<< Assign guest_username inside the script

docker exec -it "\${container_name}" bash -c 'FIRST_LAUNCH=1 exec bash'

EOL

chmod +x "${run_script_file}"
echo "Run script created at ${run_script_file}"
echo
echo "To start your docker environment for the first time run ${run_script_file} "

