#!/bin/bash

# Make sure only root can run our script
if [[ "$(id -u)" -ne 0 ]]
 then
   echo "This script must be run as root" 1>&2
   exit 1
fi

upgrade()
{
  echo -n "Upgrade the system? (y/n) "
  read -r touche </dev/tty
  if [[ "$touche" = "y" || "$touche" = "o" ]]
   then
    apt-get update && apt-get -y upgrade
  fi
}

timezone()
{
  echo -n "Update timezone? (y/n) "
  read -r touche </dev/tty
  if [[ "$touche" = "y" || "$touche" = "o" ]]
  then
    apt-get install ntp ntpdate </dev/tty
    if dpkg -l tzdata; then
      apt-get install -y tzdata
    else
      dpkg-reconfigure tzdata
    fi
  fi
}

password()
{
  echo -n "Define / change the root password (usefull for recovery mode)? (y/n) "
  read -r touche </dev/tty
  if [[ "$touche" = "y" || "$touche" = "o" ]]
  then
    passwd </dev/tty
  fi
}

force_rsa()
{
  echo -n "Disable root login using password? (only rsa key) (y/n) "
  read -r touche </dev/tty
  if [[ "$touche" = "y" || "$touche" = "o" ]]
  then
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
    /etc/init.d/ssh restart
  fi
}

add_swap()
{
  free -h
  echo -n "Add swap? (highly recommended) (y/n) "
  read -r touche </dev/tty
  if [[ "$touche" = "y" || "$touche" = "o" ]]
  then
    read -rp "What's the size (in GB)? Please input a number between 1 and 4: " swap_value </dev/tty
    echo "creating ${swap_value}G swap file"
    fallocate -l "${swap_value}G" /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
    echo 'vm.swappiness = 10' >> /etc/sysctl.conf
    echo 'vm.vfs_cache_pressure=50' >> /etc/sysctl.conf
  fi
}

mount_vol()
{
  echo -n "Mount a volume (like /dev/vdx)? (y/n) "
  read -r touche </dev/tty
  if [[ "$touche" = "y" || "$touche" = "o" ]]
  then
    fdisk -l
    read -rp "Specify volume name (eg. vdb): " volume_name </dev/tty
    read -rp "Specify destination path (eg. /apps): " path_name < /dev/tty
    read -rp "Do you really want to format and mount the volume /dev/${volume_name} on ${path_name} ? (y/n) : " touche </dev/tty
    if [[ "$touche" = "y" || "$touche" = "o" ]]
    then
      mkfs -t ext4 "/dev/${volume_name}"
      mkdir -p ${path_name}
      mount "/dev/${volume_name}" ${path_name}
      uuid_value=$(blkid -o value -s UUID /dev/${volume_name})
      echo "UUID=\"${uuid_value}\" ${path_name} ext4 defaults,nofail 0 2" >> /etc/fstab
    fi
  fi
}

install_docker()
{
  echo -n "Install Docker from docker-ce repository? (y/n)"
  read -r touche </dev/tty
  if [[ "$touche" = "y" || "$touche" = "o" ]]
  then
    apt install apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
    apt update
    apt-cache policy docker-ce
    apt install docker-ce
    systemctl status docker
  fi
}

install_docker_compose()
{
  echo -n "Install Docker Compose v1.27.4 from docker github repository? (y/n)"
  read -r touche </dev/tty
  if [[ "$touche" = "y" || "$touche" = "o" ]]
  then
    #read -rp "Specify the desired version (default. 1.27.4): " compose_version </dev/tty
    curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    docker-compose --version
  fi
}

function trap_ctrlc()
{
  echo "Ctrl^C, exiting..."
  exit 2
}


vps_prepare()
{
  trap "trap_ctrlc" 2 # SIGINT
  upgrade
  timezone
  password
  force_rsa
  add_swap
  mount_vol
  install_docker
  install_docker_compose
}

vps_prepare "$@"
