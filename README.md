# MeshWatch 🕸️

**Système de surveillance dynamique des flux réseau pour serveurs de jeu**

MeshWatch est un outil de monitoring réseau avancé conçu spécifiquement pour surveiller les flux sortants des serveurs de jeu dans un environnement de serveurs maillés (mesh). Il offre une surveillance temps réel, la détection d'anomalies et un système d'alertes intégré.

## 🚀 Fonctionnalités

### 🎛️ Interface Interactive
- **Menu bilingue** (Français/Anglais) avec navigation intuitive
- **ASCII Art** personnalisé pour une identité visuelle forte
- **Configuration en temps réel** sans redémarrage nécessaire
- **Vue des flux en direct** avec rafraîchissement automatique

### 📊 Surveillance Réseau
- **Monitoring des ports** configurables (liste ou plages)
- **Calcul du débit** réseau en temps réel (Mbps)
- **Comptage des connexions** actives sur les ports surveillés
- **Vérification de connectivité** avec serveur orchestrateur
- **Auto-détection** de l'interface réseau principale

### 🚨 Système d'Alertes
- **Détection d'anomalies** automatique :
  - Débit réseau élevé
  - Trop de connexions simultanées
  - Timeout avec l'orchestrateur
  - Absence de flux sortant
- **Alertes Discord** avec embeds colorés et informations détaillées
- **Système de cooldown** pour éviter le spam d'alertes
- **Journalisation locale** avec rotation automatique

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

## 🎮 Configuration pour Serveurs de Jeu

### Minecraft
```bash
PORTS="25565"
ORCHESTRATOR_HOST="lobby.minecraft-server.com"
MAX_CONN="100"
MAX_BANDWIDTH_MBPS="200"
```

### ARK: Survival Evolved
```bash
PORTS="7777,7778,27015"
ORCHESTRATOR_HOST="cluster.ark-server.com"
MAX_CONN="70"
MAX_BANDWIDTH_MBPS="500"
```

### Multi-jeux
```bash
PORTS="7777,25565,27015,7000-8000"
ORCHESTRATOR_HOST="orchestrator.gaming-network.com"
MAX_CONN="200"
MAX_BANDWIDTH_MBPS="1000"
```

## 🔧 Configuration Discord

### Création du Webhook
1. Aller dans les **paramètres du serveur Discord**
2. Sélectionner **Intégrations** → **Webhooks**
3. Cliquer sur **Nouveau Webhook**
4. Configurer le nom et le canal
5. **Copier l'URL du webhook**

### Format de l'URL
```
https://discord.com/api/webhooks/123456789/abcdefghijklmnopqrstuvwxyz
```

### Test du Webhook
MeshWatch teste automatiquement le webhook lors de la configuration et envoie un message de confirmation.

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
10) Quitter
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
```

### Vue des Flux en Direct

La vue temps réel affiche :
- **Connexions actives** sur les ports surveillés
- **Statistiques réseau** de l'interface
- **Processus réseau** utilisant les ports
- **Rafraîchissement automatique** toutes les 2 secondes

Utilisez `Ctrl+C` pour revenir au menu principal.

## 🔍 Monitoring et Alertes

### Types d'Anomalies Détectées

1. **Débit élevé** 🟡
   - Seuil dépassé sur le débit réseau
   - Couleur : Orange dans Discord

2. **Trop de connexions** 🟠
   - Nombre de connexions simultanées dépassé
   - Couleur : Orange dans Discord

3. **Timeout orchestrateur** 🔴
   - Perte de connectivité avec le serveur orchestrateur
   - Couleur : Rouge dans Discord

4. **Absence de flux sortant** 🟡
   - Aucune activité réseau détectée
   - Couleur : Orange dans Discord

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
```

## 🛡️ Sécurité et Bonnes Pratiques

### Permissions
- **Exécution utilisateur** : Recommandé (éviter root)
- **Fichiers de configuration** : Lecture/écriture utilisateur uniquement
- **Logs** : Accessible en lecture pour analyse

### Webhook Discord
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

## 🤝 Contribution

### Signaler un Bug
1. Vérifier que le bug n'est pas déjà signalé
2. Fournir les informations système (OS, version Bash)
3. Inclure les logs pertinents
4. Décrire les étapes pour reproduire

### Proposer une Amélioration
1. Décrire clairement la fonctionnalité souhaitée
2. Expliquer le cas d'usage
3. Proposer une implémentation si possible

### Développement
1. Fork du projet
2. Créer une branche pour la fonctionnalité
3. Respecter le style de code existant
4. Tester sur différents environnements
5. Soumettre une pull request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 🙏 Remerciements

- **Communauté gaming** pour les retours et suggestions
- **Contributeurs** pour les améliorations et corrections
- **Testeurs** pour la validation sur différents environnements

---

**MeshWatch v2.0** - Surveillance réseau intelligente pour serveurs de jeu 🎮