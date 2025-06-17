#!/bin/bash

# Mettre à jour les paquets
echo "Mise à jour des paquets..."
sudo apt update && sudo apt upgrade -y

# Obtenir l'adresse IP de la machine
echo "Récupération de l'adresse IP de la machine..."
ip=$(ip -4 addr show ens33 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo "Adresse IP de la machine veuillez la noter quelque part: $ip"

# Installer Docker
echo "Installation de Docker..."
sudo apt install -y docker.io

# Activer Docker au démarrage
echo "Activation de Docker au démarrage..."
sudo systemctl enable docker
sudo systemctl start docker

# Ajouter l'utilisateur au groupe sudo et docker
echo "Ajout de l'utilisateur au groupe sudo et docker..."
sudo usermod -aG sudo $USER
sudo usermod -aG docker $USER
newgrp docker

echo "Initialisation du manager swarm"
docker swarm init --advertise-addr $ip
echo "Token pour les workers veillez a le noter:"
docker swarm join-token worker -q

echo "Installation du volume partagé"
sudo apt install nfs-kernel-server -y
sudo mkdir -p /mnt/mc-data
sudo chown 1000:1000 /mnt/mc-data

echo "/mnt/mc-data *(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server

echo "Script terminé. Veuillez redémarrer votre session pour appliquer toutes les modifications."
