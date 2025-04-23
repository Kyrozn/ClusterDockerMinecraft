#!/bin/bash

# Mettre à jour les paquets
echo "Mise à jour des paquets..."
sudo apt update && sudo apt upgrade -y

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

read -p "Entrez le token du Docker Swarm: " token
echo "Token récupéré: $token"

read -p "Entrez l'ip de la machine Manager: " IP
echo "Ip récupéré: $IP"

echo "Ajout du worker au cluster swarm"
docker swarm join --token $token $IP:2377

echo "Configuration NFS"
sudo apt install nfs-common -y
sudo mkdir -p /mnt/mc-data
sudo mount $IP:/mnt/mc-data /mnt/mc-data

echo "$IP:/mnt/mc-data /mnt/mc-data nfs defaults 0 0" | sudo tee -a /etc/fstab

echo "Script terminé. Veuillez redémarrer votre session pour appliquer toutes les modifications."