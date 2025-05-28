#!/bin/bash
set -e
YE='\033[0;33m' # Yellow
NC='\033[0m' # No Color
echo -e $YE

echo "*************************************************************************"
echo "********************** Setting up user **********************************"
echo "*************************************************************************"
echo -e $NC
# --------------------- user configuration ---------------------

# Ensure UID and USERNAME are set
if [[ -z "$uid" || -z "$username" ]]; then
    echo "Error: uid or username is not set. Exiting."
    exit 1
fi

echo "Checking for existing UID: ${uid}"

# Get the existing user for UID 1000
existing_user=$(getent passwd "${uid}" | cut -d: -f1)

if [ -n "$existing_user" ]; then
    echo "UID ${uid} already exists and belongs to user: ${existing_user}"
	userdel ${existing_user}

fi

# Configure internal user IDs as the host user
groupadd -g ${gid:-1000} ${username}
useradd --create-home ${username} \
    --uid ${uid:-1000} --gid ${gid:-1000} \
    --shell /bin/bash

# Disable password for new user creation ${username}
passwd -d ${username}
echo "${username} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${username}
chmod 0440 /etc/sudoers.d/${username}
echo "Recursively changing ownership of /home/${username} to ${uid}:${gid}"
chown ${uid}:${gid} -R /home/${username}
# ssh-keygen -A

# create missing groups spi i2c gpio
echo "Creating missing groups spi i2c gpio"
groupadd -f -g 13 i2c
groupadd -f -g 20 gpio
groupadd -f -g 44 spi

# Add user to groups
echo "Adding user to groups"
usermod -aG sudo ${username}
usermod -aG adm ${username}
usermod -aG dialout ${username}
usermod -aG cdrom ${username}
usermod -aG video ${username}
usermod -aG gpio ${username}
usermod -aG spi ${username}
usermod -aG i2c ${username}

echo "Setting up user environment variables by modifying .bashrc"
echo "username: ${username} ros_distro: ${ros_distro} components_path: ${components_path}"

# Creating the .bashrc

cat >> /home/${username}/.bashrc << EO_BASHRC
# check if the current directory has git active, if so prompt current branch name
parse_git_branch() {
git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1) /'
}

# Terminal themes and appearances
LS_COLORS='rs=0:di=1;35:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.lz=01;31:*.xz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.axv=01;35:*.anx=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.axa=00;36:*.oga=00;36:*.spx=00;36:*.xspf=00;36:';
export LS_COLORS
ASCII_NAMES=(
  "[≋_≋]──┐ T-800 "
  "{◉‿◉}⇢ Shakey"
  "[¬º-°]⊃ Chappie "
  "<x_x>⟩ GIR "
  "[-•_•-] Marvin "
  "[∎_∎]⇨ M-O "
)

CONTAINER_NAME="\${ASCII_NAMES[RANDOM % 6]}"

PS1="\[\033[1;97m\]\u\[\033[38;5;67m\]@\${CONTAINER_NAME:-[×_×]} \[\033[1;36m\]\W\[\033[1;35m\]\$(parse_git_branch)\[\033[0m\] \$ "

# TODO: investigate if needed
export BUILDDIR=/tmp

export MAKEFLAGS="-j\$(nproc) \$MAKEFLAGS"
export PATH="\$HOME/.local/bin:\$PATH"
export LD_LIBRARY_PATH="/usr/lib:/usr/local/lib:\$LD_LIBRARY_PATH"
export PYTHONPATH="/usr/lib/python3/dist-packages:\$PYTHONPATH"


# Tmux server override (in order to not overlap with host server)
# without this, when running tmux you would leave the docker's root and enter 
# your host system's root 
export TMUX_TMPDIR=/tmp/\$(whoami)-tmux
mkdir -p \$TMUX_TMPDIR

# Tmuxinator quick launcher
alias tmux-start="tmuxinator start -p"

sudo chown -R ${username}:${username} ~/*

#source ${components_path}/install/local_setup.bash
#source /opt/ros/${ros_distro}/setup.bash

# ugly fix for gedit not being able to find a dbus session:
alias gedit='dbus-launch gedit'

# Quality of life aliases
alias gbash="gedit /home/${username}/.bashrc"
export LD_LIBRARY_PATH=/home/${username}/ros_ws/devel/lib:/opt/ros/${ros_distro}/lib:/usr/lib:/usr/local/lib:/usr/lib/x86_64-linux-gnu
alias source_ros="export LD_LIBRARY_PATH=/home/${username}/ros_ws/devel/lib:/opt/ros/${ros_distro}/lib:/usr/lib:/usr/local/lib:/usr/lib/x86_64-linux-gnu"
alias chp="echo \$LD_LIBRARY_PATH"
# alias inst='sudo apt install'
# alias search='sudo apt search'
# alias remove='sudo apt remove'
# alias clean='sudo apt-get clean'
# alias up='sudo apt update'
# alias upp='sudo apt update && sudo apt upgrade'

# alias gadd='git add'
# alias gcom='git commit'
# alias glog='git log --oneline --graph --decorate --all -5'
# alias gl='git log --oneline --all --graph --decorate'
# alias gpush='git push'
# alias gstat='git status'


if [[ "\$FIRST_LAUNCH" == "1" ]]; then

    cd /home/${username}/wss_setup
    chmod +x ros_setup.sh
    ./ros_setup.sh
    cd /home/${username}
    export FIRST_LAUNCH=0
    rm -rf wss_setup

fi

# ROS environment setup
source /opt/ros/${ros_distro}/setup.bash
source /home/${username}/ros_ws/install/local_setup.bash

# ROS aliases
alias colbu="colcon build --symlink-install --event-handler console_direct+"
alias colcl="rm -rf build/ install/ log/"



EO_BASHRC

echo -e $YE
echo "*************************************************************************"
echo "********************** User setup completed *****************************"
echo "*************************************************************************"
echo -e $NC