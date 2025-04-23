# ClusterDockerMinecraft - Enhanced Documentation
![Minecraft Cluster](https://img.shields.io/badge/Minecraft-Cluster-brightgreen) ![Docker Swarm](https://img.shields.io/badge/Docker-Swarm-blue) ![NFS Storage](https://img.shields.io/badge/Storage-NFS-orange)

## 🌟 Overview

This project enables the deployment of a scalable Minecraft server cluster using Docker Swarm, featuring:

- **Shared world generation** through identical seeds
- **Persistent player data** across all servers via shared NFS storage
- **Easy horizontal scaling** to accommodate more players
- **High availability** with automatic failover

## 🚀 Key Features

| Feature | Benefit |
|---------|---------|
| Shared NFS Volume | Consistent world and player data across all instances |
| PaperMC Server | Improved performance over vanilla Minecraft |
| Host Networking | Simplified network configuration |
| Portainer Integration | Visual cluster management |
| Auto-restart Policy | High availability |
## 🛠️ Prerequisites

### Hardware Requirements
- 1 Manager VM (2GB RAM minimum)
- 2+ Worker VMs (1GB RAM each minimum)
- 20GB shared storage (for world data)

### Software Requirements
- Ubuntu 20.04/22.04 on all nodes
- Docker installed on all machines
- NFS server on manager
- NFS client on workers

## 🧰 Installation Guide
You can use the file in the repository or config manualy with the next tuto 
### 1. System Preparation

```bash
# On ALL nodes (manager and workers):
sudo apt update && sudo apt upgrade -y
sudo apt install -y docker.io docker-compose
sudo systemctl enable --now docker
```
### 2. Initialize Docker Swarm
```bash
# ONLY on manager node:
docker swarm init --advertise-addr <MANAGER_IP>
```
### 3. Join Worker Nodes
```bash
# On EACH worker node:
docker swarm join --token <SWARM_TOKEN> <MANAGER_IP>:2377
```
💡 Get the join token with docker swarm join-token worker on the manager

### 4. Configure Shared NFS Storage
On Manager:
```bash
sudo apt install nfs-kernel-server -y
sudo mkdir -p /mnt/mc-data
sudo chown 1000:1000 /mnt/mc-data  # Match container user

echo "/mnt/mc-data *(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
```
On Workers:
```bash
sudo apt install nfs-common -y
sudo mkdir -p /mnt/mc-data
echo "<MANAGER_IP>:/mnt/mc-data /mnt/mc-data nfs defaults 0 0" | sudo tee -a /etc/fstab
sudo mount -a
```
5. Deploy Minecraft Stack
Create stack-minecraft.yml:

```yaml
version: "3.8"

services:
  minecraft:
    image: itzg/minecraft-server:java17
    deploy:
      replicas: 2
      restart_policy:
        condition: any
      placement:
        constraints: [node.role==worker]
    ports:
      - target: 25565
        published: 25565
        protocol: tcp
        mode: host
    environment:
      EULA: "TRUE"
      MEMORY: "2G"
      LEVEL: "world"
      SEED: "default"  # Change for custom world
      TYPE: "VANILLA" # Change for custom type like PAPER, see documentation
      VERSION: "1.20.1" #Change the server version
    volumes:
      - /mnt/mc-data:/data

volumes:
  mc-data:
    driver_opts:
      type: "nfs"
      o: "addr=<MANAGER_IP>,rw"
      device: ":/mnt/mc-data"
```
### Deploy the stack:

```bash
docker stack deploy -c stack-minecraft.yml mc_cluster
```
🔍 Monitoring
Portainer Setup (Optional)
```bash
docker volume create portainer_data
docker run -d -p 9000:9000 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce
Access at: http://<MANAGER_IP>:9000
```
⚙️ Operations
Scaling Servers
```bash
# Scale up
docker service scale mc_minecraft=3

# Scale down
docker service scale mc_minecraft=2
```
Checking Status
```bash
# List services
docker service ls

# View logs
docker service logs mc_minecraft
```
🛠️ Troubleshooting
Issue	Solution
Connection refused	Check firewall: sudo ufw allow 25565/tcp .
Permission denied on NFS	Run: sudo chown -R 1000:1000 /mnt/mc-data .
Server not starting	Check EULA: echo "eula=true" > /mnt/mc-data/eula.txt .
High latency	Reduce view-distance in server.properties .
📈 Performance Tips
Allocate more RAM by modifying MEMORY in stack file (e.g., "4G")

Use PaperMC optimizations by adding these environment variables:

```yaml
environment:
  PAPERMC_OPTIMIZATIONS: "true"
  VIEW_DISTANCE: "6"
```
Pre-generate chunks using Chunky plugin to reduce lag

🔄 Backup Strategy
```bash
# On manager node:
sudo mkdir -p /backups/minecraft
sudo tar -czf /backups/minecraft/world-$(date +%Y%m%d).tar.gz -C /mnt/mc-data world/
```
💡 Schedule daily backups with cron: 0 3 * * * root /path/to/backup-script.sh
