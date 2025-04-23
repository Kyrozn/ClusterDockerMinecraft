# ClusterDockerMinecraft
Cluster Minecraft avec Docker Swarm
Guide d'installation et de configuration
📋 Vue d'ensemble
Ce projet permet de déployer plusieurs serveurs Minecraft dans un cluster Docker Swarm avec:
Une seed commune pour que les mondes soient identiques
Un volume de données partagé pour que les joueurs retrouvent leurs données
Possibilité d'ajouter facilement de nouveaux serveurs via des Workers
🧾 Objectif
Permettre à plusieurs conteneurs Minecraft de partager le même monde et les mêmes données (inventaires, stats, etc.) à travers plusieurs machines grâce à Docker Swarm, tout en gardant une seed identique.
📦 Prérequis
1 VM Manager
2+ VM Workers
Docker installé sur chaque VM
Swarm initialisé
Un volume partagé (par NFS ou GlusterFS)
🔧 Étapes d'installation
1. Installer Docker sur toutes les machines
Tu peux utiliser ce script shell sur chaque VM :
#!/bin/bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker

2. Initialiser le Swarm (sur le manager uniquement)
docker swarm init --advertise-addr <IP_MANAGER>

Note : remplace <IP_MANAGER> par l'adresse IP de la machine manager.
3. Ajouter les Workers au cluster
Depuis les Workers :
docker swarm join --token <TOKEN> <IP_MANAGER>:2377

Récupère le token avec docker swarm join-token worker sur le manager.
4. Configurer un volume partagé (NFS recommandé)
Sur le manager :
sudo apt install nfs-kernel-server -y
sudo mkdir -p /mnt/mc-data
sudo chown nobody:nogroup /mnt/mc-data

Ajouter dans /etc/exports :
/mnt/mc-data *(rw,sync,no_subtree_check)

Puis :
sudo exportfs -a
sudo systemctl restart nfs-kernel-server

Sur les workers :
sudo apt install nfs-common -y
sudo mkdir -p /mnt/mc-data
sudo mount <IP_MANAGER>:/mnt/mc-data /mnt/mc-data

⚠️ Important : Pour rendre ça persistant au reboot, tu peux modifier /etc/fstab en ajoutant :
<IP_MANAGER>:/mnt/mc-data /mnt/mc-data nfs defaults 0 0

5. Fichier stack Minecraft pour Swarm
Crée un fichier stack-minecraft.yml :
version: "3.8"

services:
  minecraft:
    image: itzg/minecraft-server
    deploy:
      replicas: 2
      restart_policy:
        condition: any
      placement:
        max_replicas_per_node: 1
    ports:
      - target: 25565
        published: 25565
        protocol: tcp
        mode: host
    environment:
      EULA: "TRUE"
      MEMORY: 2G
      LEVEL: "world"
      SEED: "ma-super-seed" # facultatif
      TYPE: PAPER # plus performant que vanilla
    volumes:
      - mc-data:/data

volumes:
  mc-data:
    driver_opts:
      type: "nfs"
      o: "addr=<IP_MANAGER>,rw"
      device: ":/mnt/mc-data"

6. Déployer la stack
docker stack deploy -c stack-minecraft.yml mc-cluster

🧪 Tester
Connecte-toi à l'IP de n'importe quelle VM avec le port 25565
Tu seras redirigé vers un des serveurs selon les règles de Swarm
Les données sont partagées, donc ton monde et ton inventaire sont toujours là
🛠️ Dépannage
Problèmes d'accès au volume partagé
Vérifiez les logs avec :
docker service logs mc-cluster_minecraft

Si vous rencontrez des problèmes de permission :
sudo chmod -R 777 /mnt/mc-data

Problèmes de connexion au serveur
Vérifiez que le port 25565 est ouvert sur les VM :
sudo ufw allow 25565/tcp

📈 Bonus : Monitoring avec Portainer
Sur le manager :
docker volume create portainer_data
docker run -d -p 9000:9000 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce

Accès : http://<IP_MANAGER>:9000
🔄 Mise à l'échelle
Pour ajouter plus de serveurs Minecraft :
docker service scale mc-cluster_minecraft=3

🎉 Résultat
Tu as un cluster Minecraft avec plusieurs conteneurs
Le monde est commun grâce au volume partagé
Les données sont partagées
Tu peux ajouter un nouveau Worker et augmenter les replicas facilement
📝 Notes supplémentaires
Cette configuration utilise le mode réseau host pour éviter les problèmes de NAT entre les conteneurs
Le plugin Paper est utilisé pour de meilleures performances
Portainer permet une gestion graphique du cluster
📚 Ressources
Documentation Docker Swarm
Image Docker Minecraft
Documentation NFS
User = master
Psw Vm Master = MinecraftInfra
User = worker1
Psw Vm worker1 = MinecraftInfra

pour ajouter un worker au swarm 👍
docker swarm join --token SWMTKN-1-2cksa9a0zip2t3al1wng4kjsdcfa9ee78zmac04amjxtx3d1g6-cjypqq7tk1utzl2oty5l7z0ja 192.168.5.10:2377
