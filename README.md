# MeshWatch 🌌 - Star Déception Network Monitor

**Système de surveillance réseau pour l'architecture meshing dynamique de Star Déception**

MeshWatch est un outil de monitoring réseau spécialement développé pour **Star Déception**, un projet de jeu multijoueur utilisant une architecture de serveurs maillés dynamiques. Il surveille les flux inter-serveurs, détecte les anomalies de connectivité et assure la stabilité du mesh réseau en temps réel.

## 🎮 À propos de Star Déception

**Star Déception** est un jeu multijoueur ambitieux utilisant une architecture de **serveur meshing dynamique** où :
- Les serveurs se connectent dynamiquement entre eux
- Les joueurs peuvent se déplacer fluidement entre différents nœuds
- La charge est répartie automatiquement selon l'activité
- La redondance assure une haute disponibilité

MeshWatch surveille cette infrastructure critique pour garantir une expérience de jeu optimale.

## 🚀 Fonctionnalités

### 🎛️ Interface Interactive
- **Menu bilingue** (Français/Anglais) avec navigation intuitive
- **ASCII Art** personnalisé pour une identité visuelle forte
- **Configuration en temps réel** sans redémarrage nécessaire
- **Vue des flux en direct** avec rafraîchissement automatique

### 🌐 Surveillance Mesh Réseau
- **Monitoring des ports mesh** configurables pour Star Déception
- **Calcul du débit inter-serveurs** en temps réel (Mbps)
- **Comptage des connexions** entre nœuds du mesh
- **Vérification de connectivité** avec l'orchestrateur central
- **Auto-détection** de l'interface réseau du mesh
- **Surveillance des flux de synchronisation** entre serveurs

### 🚨 Système d'Alertes Mesh
- **Détection d'anomalies** spécifiques au meshing :
  - Débit inter-serveurs anormal
  - Perte de connexion avec nœuds voisins
  - Timeout avec l'orchestrateur central
  - Désynchronisation du mesh
  - Surcharge d'un nœud spécifique
- **Alertes Discord** pour l'équipe Star Déception
- **Système de cooldown** intelligent
- **Journalisation** des événements mesh critiques

### 📊 Surveillance Temporaire et Rapports
- **Surveillance temporaire** avec durée configurable
- **Collecte de données** détaillée pendant la surveillance
- **Génération de rapports** automatique (TXT/HTML)
- **Analyse statistique** des performances mesh
- **Recommandations** basées sur les données collectées
- **Rapports HTML interactifs** avec graphiques et métriques
- **Historique des rapports** avec gestion automatique

### ⚙️ Configuration Avancée
- **Seuils personnalisables** pour tous les types d'alertes
- **Webhook Discord** avec test de connectivité
- **Niveaux de log** configurables (DEBUG/INFO/WARN/ERROR)
- **Interface réseau** sélectionnable
- **Sauvegarde automatique** de la configuration

## 📁 Structure du Projet

```
meshwatch/
├── meshwatch.sh          # Script principal
├── src/                  # Modules sources
│   ├── config.sh        # Gestion de la configuration
│   ├── network.sh       # Surveillance réseau
│   ├── alerts.sh        # Système d'alertes
│   ├── ui.sh           # Interface utilisateur
│   ├── monitoring.sh    # Boucle de monitoring
│   └── utils.sh        # Fonctions utilitaires
├── config/              # Fichiers de configuration
│   ├── meshwatch.conf  # Configuration utilisateur
│   └── default.conf    # Configuration par défaut
├── reports/            # Rapports générés
│   ├── meshwatch_report_YYYYMMDD_HHMMSS.txt
│   └── meshwatch_report_YYYYMMDD_HHMMSS.html
├── logs/               # Journaux
│   └── meshwatch.log   # Log principal
└── docs/              # Documentation
    └── README.md      # Ce fichier
```

## 🛠️ Installation

### Prérequis
- **Système d'exploitation** : Linux (Ubuntu, Debian, CentOS, etc.)
- **Bash** version 4.0 ou supérieure
- **Outils réseau** : `ss`, `curl`, `ping`, `netstat`, `ip`

### Installation des dépendances

**Ubuntu/Debian :**
```bash
sudo apt update
sudo apt install iproute2 curl iputils-ping net-tools
```

**CentOS/RHEL :**
```bash
sudo yum install iproute curl iputils net-tools
# ou pour les versions récentes :
sudo dnf install iproute curl iputils net-tools
```

### Installation de MeshWatch

1. **Cloner ou télécharger** le projet :
```bash
git clone <repository-url> meshwatch
cd meshwatch
```

2. **Rendre le script exécutable** :
```bash
chmod +x meshwatch.sh
chmod +x src/*.sh
```

3. **Lancer MeshWatch** :
```bash
./meshwatch.sh
```

## 🔧 Configuration pour Star Déception

### Serveur Mesh Principal
```bash
PORTS="7777,7778,7779"  # Ports mesh Star Déception
ORCHESTRATOR_HOST="orchestrator.star-deception.com"
MAX_CONN="150"          # Connexions inter-serveurs
MAX_BANDWIDTH_MBPS="500" # Débit mesh élevé
```

### Nœud Secondaire
```bash
PORTS="7780-7790"       # Plage dynamique
ORCHESTRATOR_HOST="mesh-coordinator.star-deception.com"
MAX_CONN="75"           # Nœud plus petit
MAX_BANDWIDTH_MBPS="250"
```

### Cluster Complet
```bash
PORTS="7777-7800,8000-8100"  # Mesh complet
ORCHESTRATOR_HOST="master.star-deception.com"
MAX_CONN="300"               # Cluster haute capacité
MAX_BANDWIDTH_MBPS="1000"    # Débit mesh maximal
```

## 🔧 Configuration Discord

### Configuration pour l'équipe
1. Aller dans le **serveur Discord Star Déception**
2. Canal **#mesh-monitoring** → **Paramètres** → **Intégrations**
3. Créer un **Nouveau Webhook** nommé "MeshWatch"
4. **Copier l'URL** pour la configuration

### Format de l'URL
```
https://discord.com/api/webhooks/STAR_DECEPTION_ID/TOKEN_MESH_MONITORING
```

### Test du Webhook
MeshWatch teste automatiquement le webhook et envoie : 
`🌌 MeshWatch Star Déception - Surveillance mesh activée !`

## 📋 Utilisation

### Interface Interactive

Lancez MeshWatch et naviguez dans le menu :

```
███╗   ███╗███████╗███████╗██╗  ██╗██╗    ██╗ █████╗ ████████╗ ██████╗██╗  ██╗███████╗██████╗ 
████╗ ████║██╔════╝██╔════╝██║  ██║██║    ██║██╔══██╗╚══██╔══╝██╔════╝██║  ██║██╔════╝██╔══██╗
██╔████╔██║█████╗  ███████╗███████║██║ █╗ ██║███████║   ██║   ██║     ███████║███████╗██║  ██║
██║╚██╔╝██║██╔══╝  ╚════██║██╔══██║██║███╗██║██╔══██║   ██║   ██║     ██╔══██║╚════██║██║  ██║
██║ ╚═╝ ██║███████╗███████║██║  ██║╚███╔███╔╝██║  ██║   ██║   ╚██████╗██║  ██║███████║██████╔╝
╚═╝     ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝╚══════╝╚═════╝

=== MeshWatch - Surveillance Réseau ===

Statut: Arrêté

1)  Démarrer la surveillance
2)  Arrêter la surveillance
3)  Configurer les ports
4)  Configurer webhook Discord
5)  Basculer journalisation
6)  Voir flux en direct
7)  Afficher configuration
8)  Changer de langue
9)  Configuration avancée
10) Surveillance temporaire + rapport
11) Voir rapports disponibles
12) Mettre à jour MeshWatch
13) Informations version
14) Quitter
```

### Ligne de Commande

```bash
# Afficher l'aide
./meshwatch.sh --help

# Vérifier le statut
./meshwatch.sh --status

# Voir la configuration
./meshwatch.sh --config

# Afficher la version
./meshwatch.sh --version

# Surveillance temporaire avec rapport
./meshwatch.sh --temp-monitor 600 html  # 10 minutes, rapport HTML
./meshwatch.sh --temp-monitor 300 txt   # 5 minutes, rapport TXT
```

### Surveillance Temporaire

La surveillance temporaire permet de collecter des données pendant une durée définie et de générer automatiquement un rapport détaillé :

1. **Configuration** : Choisir la durée (minimum 30 secondes) et le format (TXT/HTML)
2. **Collecte** : Surveillance avec barre de progression en temps réel
3. **Analyse** : Calcul automatique des statistiques et métriques
4. **Rapport** : Génération d'un rapport complet avec recommandations

**Données collectées :**
- Nombre de connexions mesh par échantillon
- Débit réseau inter-serveurs (Mbps)
- État de l'orchestrateur Star Déception
- Connexions actives et processus réseau
- Statistiques de trafic (RX/TX bytes)

**Rapports générés :**
- **TXT** : Rapport texte simple avec toutes les données
- **HTML** : Rapport web interactif avec mise en forme avancée

### Vue des Flux en Direct

La vue temps réel affiche :
- **Connexions actives** sur les ports surveillés
- **Statistiques réseau** de l'interface
- **Processus réseau** utilisant les ports
- **Rafraîchissement automatique** toutes les 2 secondes

Utilisez `Ctrl+C` pour revenir au menu principal.

## 🔍 Monitoring et Alertes

### Types d'Anomalies Mesh Détectées

1. **Surcharge Mesh** 🟡
   - Débit inter-serveurs anormalement élevé
   - Peut indiquer une migration massive de joueurs

2. **Saturation Nœud** 🟠
   - Trop de connexions simultanées sur un nœud
   - Nécessite redistribution de charge

3. **Perte Orchestrateur** 🔴
   - Connexion perdue avec l'orchestrateur central
   - Risque de désynchronisation du mesh

4. **Isolation Nœud** 🔴
   - Nœud isolé du mesh (aucun flux sortant)
   - Nécessite reconnexion d'urgence

### Système de Cooldown

Pour éviter le spam d'alertes, MeshWatch implémente un système de cooldown :
- **Cooldown par défaut** : 5 minutes (300 secondes)
- **Configurable** via le menu avancé
- **Par type d'alerte** : chaque type a son propre cooldown

## 📊 Journalisation

### Niveaux de Log
- **DEBUG** : Informations détaillées pour le débogage
- **INFO** : Informations générales sur le fonctionnement
- **WARN** : Avertissements et anomalies détectées
- **ERROR** : Erreurs critiques

### Rotation Automatique
- **Taille maximum** : 10MB par défaut
- **Historique** : 5 fichiers de rotation conservés
- **Automatique** : Rotation transparente sans interruption

### Localisation des Logs
```
meshwatch/logs/meshwatch.log      # Log principal
meshwatch/logs/meshwatch.log.1    # Rotation précédente
meshwatch/logs/meshwatch.log.2    # ...
meshwatch/reports/                # Rapports de surveillance
```

## 🛡️ Sécurité et Bonnes Pratiques

### Permissions
- **Exécution utilisateur** : Recommandé (éviter root)
- **Fichiers de configuration** : Lecture/écriture utilisateur uniquement
- **Logs** : Accessible en lecture pour analyse

### Webhook Discord Star Déception
- **URL sécurisée** : Ne jamais partager l'URL du webhook
- **Test automatique** : Validation lors de la configuration
- **Masquage** : L'URL est partiellement masquée dans l'affichage

### Monitoring Réseau
- **Ports privilégiés** : Certains ports peuvent nécessiter des permissions élevées
- **Interfaces réseau** : Auto-détection sécurisée
- **Processus isolé** : Le daemon de monitoring est isolé

## 🔧 Dépannage

### Problèmes Courants

**1. "Commande non trouvée : ss"**
```bash
# Ubuntu/Debian
sudo apt install iproute2

# CentOS/RHEL
sudo yum install iproute
```

**2. "Permission denied" sur les logs**
```bash
# Vérifier les permissions
ls -la meshwatch/logs/
# Corriger si nécessaire
chmod 755 meshwatch/logs/
chmod 644 meshwatch/logs/meshwatch.log
```

**3. "Interface réseau non détectée"**
```bash
# Lister les interfaces disponibles
ip link show
# Configurer manuellement dans le menu avancé
```

**4. "Webhook Discord ne fonctionne pas"**
- Vérifier l'URL du webhook
- Tester avec le menu de configuration
- Vérifier les permissions du bot Discord

### Logs de Débogage

Activez le niveau DEBUG pour plus d'informations :
```bash
# Dans le menu : Configuration avancée → Niveau de log → DEBUG
```

### Nettoyage

Pour nettoyer complètement MeshWatch :
```bash
# Arrêter le monitoring
./meshwatch.sh --status
# Si en cours, utiliser le menu pour arrêter

# Supprimer les fichiers temporaires
rm -f /tmp/meshwatch*
rm -rf /tmp/meshwatch_cooldowns/

# Optionnel : supprimer la configuration
rm -f meshwatch/config/meshwatch.conf
```

## 🤝 Contribution au Projet Star Déception

### Signaler un Problème Mesh
1. Vérifier dans **#mesh-monitoring** si le problème est connu
2. Fournir les **logs MeshWatch** et configuration serveur
3. Inclure la **topologie mesh** au moment du problème
4. Mentionner l'**impact sur les joueurs** Star Déception

### Améliorer le Monitoring
1. Proposer des **métriques mesh** spécifiques
2. Suggérer des **seuils optimaux** pour Star Déception
3. Contribuer aux **alertes intelligentes**

### Développement
1. Comprendre l'**architecture mesh** de Star Déception
2. Tester sur l'**environnement de développement** mesh
3. Valider avec l'**équipe infrastructure**
4. Déployer sur les **serveurs de test** avant production

### Rapports et Analyse
1. Utiliser la **surveillance temporaire** pour collecter des données
2. Analyser les **rapports HTML** pour identifier les tendances
3. Partager les **métriques de performance** avec l'équipe
4. Optimiser la **configuration mesh** basée sur les recommandations

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 🌌 Remerciements Star Déception

- **Équipe Star Déception** pour la vision du meshing dynamique
- **Développeurs mesh** pour l'architecture innovante
- **Testeurs alpha** pour la validation en conditions réelles
- **Communauté** pour les retours sur la stabilité réseau

---

**MeshWatch v2.1** - Surveillance mesh pour Star Déception 🌌🕸️