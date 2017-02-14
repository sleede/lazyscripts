#!/bin/bash

# Make sure only root can run our script
if [ $(id -u) -ne 0 ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo -n "Mettre à jour le systeme ? (o/n) "
read touche
if [ "$touche" = "o" ];then
  apt-get update && sudo apt-get upgrade
fi

echo -n "Mettre à jour la timezone ? (o/n) "
read touche
if [ "$touche" = "o" ];then
  apt-get install ntp ntpdate
  dpkg-reconfigure tzdata
fi

echo -n "Définir / modifier le mdp root (utile pour le recovery mode) ? (o/n) "
read touche
if [ "$touche" = "o" ];then
  passwd
fi

echo -n "Désactiver le login root par mdp ? (only rsa key) (o/n) "
read touche
if [ "$touche" = "o" ];then
  sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
  /etc/init.d/ssh restart
fi

echo -n "Ajouter la swap ? (fortement recommandé) (o/n) "
read touche
if [ "$touche" = "o" ];then
  read -p "Saisir un entier de 1 à 4 : " swap_value
  echo "creating ${swap_value}G swap file"
  fallocate -l ${swap_value}G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
  echo 'vm.swappiness = 10' >> /etc/sysctl.conf
  echo 'vm.vfs_cache_pressure=50' >> /etc/sysctl.conf
fi

echo -n "Monter un volume /dev/vdx ? (o/n) "
read touche
if [ "$touche" = "o" ];then
  fdisk -l
  read -p "indiquer le nom du volume (ex vdb) : " volume_name
  read -p "Etes vous sur de vouloir formater et monter le volume /dev/${volume_name} sur /apps ? (o/n) : " touche
  if [ "$touche" = "o" ];then
    mkfs -t ext4 /dev/${volume_name}
    mkdir -p /apps
    mount /dev/${volume_name} /apps
    uuid_value=$(blkid -o value -s UUID /dev/${volume_name})
    echo "UUID=\"${uuid_value}\" /apps ext4 defaults 0 2" >> /etc/fstab
  fi
fi
