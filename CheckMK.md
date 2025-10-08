# Documentation : Mise en Place Supervision CheckMK

## Documentation : Mise en Place Supervision CheckMK

### **1. Installation**

**A. Déploiement Container CheckMK :**
```bash
# Création du conteneur CheckMK
docker run -d \
  --name monitoring \
  --hostname checkmk-server \
  -p 8080:5000 \
  -p 8000:8000 \
  -v checkmk_data:/opt/omd/sites \
  -e CMK_SITE_ID=cmk \
  --restart always \
  checkmk/check-mk-raw:2.4.0p12

# Vérification du déploiement
docker ps | grep monitoring
docker logs monitoring

# Première connexion
# URL : http://localhost:8080/cmk
# User : cmkadmin
# Password : voir logs docker pour mot de passe initial
```

**B. Installation Agent CheckMK sur l'hôte :**
```bash
# Téléchargement de l'agent depuis l'interface web
# Setup → Agents → Linux → DEB (64-bit)
wget "http://localhost:8080/cmk/check_mk/agents/check-mk-agent_2.4.0p12-1_all.deb"

# Installation
sudo dpkg -i check-mk-agent_2.4.0p12-1_all.deb
sudo apt-get install -f  # résoudre dépendances si nécessaire

# Configuration des services
sudo systemctl enable check-mk-agent.socket
sudo systemctl enable check-mk-agent-async.service
sudo systemctl start check-mk-agent.socket
sudo systemctl start check-mk-agent-async.service

# Vérification
sudo systemctl status check-mk-agent.socket
sudo systemctl status check-mk-agent-async.service
ss -tlnp | grep 6556
```

**C. Test de communication Agent :**
```bash
# Test local de l'agent
/usr/bin/check_mk_agent | head -20

# Test depuis le serveur CheckMK
# Dans le conteneur ou via l'interface web
telnet [IP_HOST] 6556
```

### **2. Configuration de Base**

**A. Ajout de l'hôte :**
- Setup → Hosts → Add host
- Hostname : `rdpc-02`
- IP : `192.168.1.200` (ou localhost)
- Agent type : CheckMK agent over TCP

**B. Découverte des services :**
- Services découverts : 25+ services automatiques
- CPU, mémoire, disques, réseau, processus
- Status : ✅ Tous services OK

### **3. Monitoring Docker - Configuration Technique**

**A. Installation plugin Docker :**
```bash
# 1. Téléchargement du plugin depuis l'interface CheckMK
# Setup → Agents → Other operating systems → Plugins → mk_docker.py
# Ou téléchargement direct :
wget "http://localhost:8080/cmk/check_mk/agents/plugins/mk_docker.py"

# 2. Installation du plugin
sudo cp mk_docker.py /usr/lib/check_mk_agent/plugins/
sudo chmod 755 /usr/lib/check_mk_agent/plugins/mk_docker.py
sudo chown root:root /usr/lib/check_mk_agent/plugins/mk_docker.py

# 3. Installation des prérequis Python
sudo apt update
sudo apt install python3-docker

# 4. Vérification
python3 -c "import docker; print('Docker module OK')"
```

**B. Configuration docker.cfg (Optionnel) :**
```bash
# Création du fichier de configuration
sudo mkdir -p /etc/check_mk
sudo tee /etc/check_mk/docker.cfg <<EOF
# Configuration du plugin Docker CheckMK

# Conteneurs à surveiller (par défaut : tous)
# restrict_containers = ["monitoring", "web"]

# Métriques à collecter
collect_container_stats = true
collect_container_labels = true
collect_network_stats = true
collect_diskstats = true

# Seuils personnalisés
cpu_warning = 80
cpu_critical = 95
memory_warning = 85
memory_critical = 95

# Debug (désactiver en production)
debug = false
EOF
```

**C. Personnalisation des métriques Docker :**
```bash
# Test du plugin avec configuration
sudo /usr/lib/check_mk_agent/plugins/mk_docker.py

# Vérification des sections générées
/usr/bin/check_mk_agent | grep -A 10 "<<<docker"

# Redémarrage de l'agent async pour prise en compte
sudo systemctl restart check-mk-agent-async.service
```

**D. Services Docker découverts :**
- Docker container status (running/stopped/health)
- Docker container info (image, labels, networks)
- Docker container CPU usage
- Docker container memory usage
- Docker container network I/O
- Docker container disk I/O
- Docker node info (daemon stats)

### **4. Résultats de Monitoring**

**Hôte rdpc-02 :**
- ✅ 1 conteneur Docker actif
- ✅ Utilisation CPU : Normal
- ✅ Mémoire : 64GB total, usage optimal
- ✅ Disques : 3 partitions surveillées
- ✅ Réseau : Interface eth0 + lo

**Conteneur CheckMK :**
- ✅ Status : Running/Healthy
- ✅ CPU : Utilisation normale
- ✅ Memory : 1.7GB utilisés
- ✅ Services internes : Tous actifs

### **5. Architecture Finale**

```
┌─────────────────┐    ┌──────────────────┐
│   Hôte rdpc-02  │    │  Container       │
│                 │    │  CheckMK         │
│ Agent CheckMK   │◄──►│  Web Interface   │
│ Plugin Docker   │    │  :8080           │
│ Port 6556       │    │                  │
└─────────────────┘    └──────────────────┘
```

**Flux de données :**
1. Agent collecte métriques système + Docker
2. CheckMK server récupère via port 6556
3. Interface web affiche dashboards
4. Alertes configurables par email/Slack

### **6. Next Steps Recommandés**

**A. Configuration alerting :**
1. Setup → Users → Créer utilisateurs admin
2. Setup → Notifications → Configurer email/Slack
3. Setup → Events → Définir règles d'escalade

**B. Monitoring avancé :**
1. Ajouter d'autres hôtes au réseau
2. Configurer seuils personnalisés
3. Créer dashboards métier

**C. Maintenance :**
1. Sauvegarde configuration CheckMK
2. Mise à jour périodique agents
3. Rotation logs et nettoyage

## Système d'Alerting CheckMK

### 1. **Architecture des Notifications**

**Flux :**
1. **Service/Host** → État critique/warning
2. **Nagios Core** → Génère l'événement
3. **Règles de notification** → Filtrage et routage
4. **Scripts de notification** → Email, SMS, Slack, etc.
5. **Destinataires** → Reçoivent l'alerte

### 2. **Configuration des Notifications**

**A. Créer des utilisateurs :**
- Setup → Users → Add user
- Définir email, téléphone, rôles

**B. Configurer les canaux :**
- Setup → Events → Notifications → Add rule
- Types : Email, SMS, Slack, PagerDuty, Webhook

**C. Règles de notification :**
```
- Conditions : Quels services/hosts
- Horaires : 24/7, heures ouvrées
- Destinataires : Qui reçoit quoi
- Escalades : Délais et niveaux
```

### 3. **Configuration Email Technique**

**A. Prérequis SMTP :**
```bash
# Option 1 : Serveur SMTP local (Postfix)
sudo apt install postfix mailutils
sudo systemctl enable postfix
sudo systemctl start postfix

# Option 2 : Relay SMTP externe (Gmail, Office365, etc.)
# Aucune installation locale nécessaire
```

**B. Configuration dans CheckMK :**
```bash
# Interface Web : Setup → Global settings → Notifications

# Configuration SMTP local :
SMTP Server: localhost
Port: 25
Encryption: None
Authentication: None
```

**C. Création des utilisateurs et notifications :**
```bash
# Via interface web :
# Setup → Users → Add user

# Exemple configuration utilisateur :
Username: ryan
FullName: Administrateur Système
Email: ryan@del.com
Roles: Administrator
NotificationMethod: Email
```

**D. Règles de notification complètes :**
```bash
# Setup → Events → Notifications → Add rule

# Règle 1 : Alertes critiques immédiates
Name: "Critical Alerts"
Conditions:
  - ServiceState: CRITICAL
  - HostState: DOWN, UNREACHABLE
NotificationMethod: HTML Email
Contacts: admin@company.com
Time period: 24/7
Delay: 0 minutes
```

**E. Test des notifications :**
```bash
# Test depuis l'interface CheckMK :
# Monitor → Overview → Clic sur un service
# "Commands" → "Send custom notification"

# Test en ligne de commande (dans le conteneur) :
docker exec -it monitoring bash
su - cmk
echo "Test notification" | mail -s "Test CheckMK" admin@company.com

# Vérification des logs
tail -f /opt/omd/sites/cmk/var/log/notify.log
```

**F. Template email personnalisé :**
```html
<!-- Fichier : ~/local/share/check_mk/notifications/mail_html_custom.html -->
<!DOCTYPE html>
<html>
<head>
    <title>CheckMK Alert</title>
    <style>
        .critical { background-color: #ff4444; color: white; }
        .warning { background-color: #ffaa00; color: black; }
        .ok { background-color: #44ff44; color: black; }
    </style>
</head>
<body>
    <h2>Alerte CheckMK - $HOSTNAME$</h2>
    <div class="$SERVICESTATE$">
        <p><strong>Service:</strong> $SERVICEDESC$</p>
        <p><strong>État:</strong> $SERVICESTATE$</p>
        <p><strong>Sortie:</strong> $SERVICEOUTPUT$</p>
        <p><strong>Heure:</strong> $LONGDATETIME$</p>
    </div>
    <p><a href="$HOSTURL$">Voir dans CheckMK</a></p>
</body>
</html>
```

### 4. **Types d'Alertes Avancées**

- **Slack** : Intégration webhook
- **Teams** : Connecteur Office 365
- **SMS** : Via passerelles (Twilio, etc.)
- **Mobile** : Apps CheckMK
- **Custom** : Scripts personnalisés
