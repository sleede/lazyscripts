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
    apt-get update && apt-get upgrade
  fi
}

timezone()
{
  echo -n "Update timezone? (y/n) "
  read -r touche </dev/tty
  if [[ "$touche" = "y" || "$touche" = "o" ]]
  then
    apt-get install ntp ntpdate
    dpkg-reconfigure tzdata
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
    read -rp "Do you really want to format and mount the volume /dev/${volume_name} on /apps? (y/n) : " touche </dev/tty
    if [[ "$touche" = "y" || "$touche" = "o" ]]
    then
      mkfs -t ext4 "/dev/${volume_name}"
      mkdir -p /apps
      mount "/dev/${volume_name}" /apps
      uuid_value=$(blkid -o value -s UUID /dev/${volume_name})
      echo "UUID=\"${uuid_value}\" /apps ext4 defaults 0 2" >> /etc/fstab
    fi
  fi
}

vps_prepare()
{
  upgrade
  timezone
  password
  force_rsa
  add_swap
  mount_vol
}

vps_prepare "$@"
