#!/bin/bash

# =============================================================================
# MeshWatch Star Déception - Surveillance mesh dynamique
# =============================================================================
# Version: 2.2.0
# Auteur: Assistant IA
# Description: Système de monitoring mesh pour Star Déception
# =============================================================================

set -euo pipefail

# Version du script
readonly MESHWATCH_VERSION="2.2.0"
readonly BUILD_DATE=$(date '+%Y%m%d')

# Variables globales
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="$SCRIPT_DIR/config"
readonly LOGS_DIR="$SCRIPT_DIR/logs"
readonly REPORTS_DIR="$SCRIPT_DIR/reports"
readonly SRC_DIR="$SCRIPT_DIR/src"

# Couleurs pour les messages
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Créer les répertoires nécessaires
mkdir -p "$CONFIG_DIR" "$LOGS_DIR" "$REPORTS_DIR"

# Exporter les variables globales pour les modules
export SCRIPT_DIR CONFIG_DIR LOGS_DIR REPORTS_DIR SRC_DIR
export MESHWATCH_VERSION BUILD_DATE
export RED GREEN YELLOW BLUE PURPLE CYAN WHITE NC

# Vérifier que le répertoire src existe
if [[ ! -d "$SRC_DIR" ]]; then
    echo -e "${RED}Erreur: Répertoire src/ non trouvé dans $SCRIPT_DIR${NC}" >&2
    echo -e "${YELLOW}Assurez-vous d'exécuter le script depuis le répertoire meshwatch/${NC}" >&2
    exit 1
fi

# Charger les modules dans le bon ordre
source "$SRC_DIR/config.sh"
source "$SRC_DIR/network.sh"
source "$SRC_DIR/alerts.sh"
source "$SRC_DIR/monitoring.sh"
source "$SRC_DIR/reports.sh"
source "$SRC_DIR/utils.sh"
source "$SRC_DIR/ui.sh"

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

main() {
    # Traiter les arguments de ligne de commande
    parse_arguments "$@"
    
    # Vérifier les dépendances
    check_dependencies
    
    # Initialiser la configuration
    init_config
    
    # Charger la configuration
    load_config
    
    # Vérifier les permissions
    check_permissions
    
    # Démarrer l'interface utilisateur
    start_ui
}

# =============================================================================
# GESTION DES SIGNAUX
# =============================================================================

# Variable pour éviter les appels multiples de cleanup
CLEANUP_CALLED=false

cleanup() {
    # Éviter les appels multiples
    if [[ "$CLEANUP_CALLED" == "true" ]]; then
        return
    fi
    CLEANUP_CALLED=true
    
    printf "\n\033[0;32mArrêt de MeshWatch Star Déception...\033[0m\n"
    
    # Arrêt direct du monitoring sans logs
    if [[ -f "/tmp/meshwatch.pid" ]]; then
        local pid=$(cat "/tmp/meshwatch.pid" 2>/dev/null || echo "")
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            kill -TERM "$pid" 2>/dev/null || true
            sleep 1
            if kill -0 "$pid" 2>/dev/null; then
                kill -KILL "$pid" 2>/dev/null || true
            fi
        fi
        rm -f "/tmp/meshwatch.pid"
    fi
    
    # Nettoyage des fichiers temporaires
    rm -f /tmp/meshwatch_stats_cache /tmp/meshwatch_interface_cache
    rm -rf /tmp/meshwatch_cooldowns
    
    exit 0
}

# Capturer les signaux
trap cleanup SIGINT SIGTERM

# =============================================================================
# POINT D'ENTRÉE
# =============================================================================

main "$@"