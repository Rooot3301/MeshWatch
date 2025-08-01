#!/bin/bash

# =============================================================================
# MeshWatch - Surveillance dynamique des flux sortants d'un serveur de jeu
# =============================================================================
# Version: 2.0
# Auteur: Assistant IA
# Description: Système de monitoring réseau avec alertes Discord
# =============================================================================

set -euo pipefail

# Variables globales
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="$SCRIPT_DIR/config"
readonly LOGS_DIR="$SCRIPT_DIR/logs"
readonly SRC_DIR="$SCRIPT_DIR/src"

# Créer les répertoires nécessaires
mkdir -p "$CONFIG_DIR" "$LOGS_DIR"

# Charger les modules
source "$SRC_DIR/config.sh"
source "$SRC_DIR/network.sh"
source "$SRC_DIR/alerts.sh"
source "$SRC_DIR/ui.sh"
source "$SRC_DIR/monitoring.sh"
source "$SRC_DIR/utils.sh"

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

main() {
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

cleanup() {
    log_message "INFO" "Arrêt propre de MeshWatch"
    stop_monitoring_safe
    exit 0
}

# Capturer les signaux
trap cleanup SIGINT SIGTERM

# =============================================================================
# POINT D'ENTRÉE
# =============================================================================

main "$@"