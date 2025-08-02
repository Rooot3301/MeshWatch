#!/bin/bash

# =============================================================================
# MeshWatch Star Déception - Surveillance mesh dynamique
# =============================================================================
# Version: 2.1.0
# Auteur: Assistant IA
# Description: Système de monitoring mesh pour Star Déception
# =============================================================================

set -euo pipefail

# Version du script
readonly MESHWATCH_VERSION="2.1.0"
readonly BUILD_DATE=$(date '+%Y%m%d')

# Variables globales
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="$SCRIPT_DIR/config"
readonly LOGS_DIR="$SCRIPT_DIR/logs"
readonly REPORTS_DIR="$SCRIPT_DIR/reports"
readonly SRC_DIR="$SCRIPT_DIR/src"

# Créer les répertoires nécessaires
mkdir -p "$CONFIG_DIR" "$LOGS_DIR" "$REPORTS_DIR"

# Charger les modules dans l'ordre correct
source "$SRC_DIR/utils.sh"
source "$SRC_DIR/config.sh"
source "$SRC_DIR/network.sh"
source "$SRC_DIR/alerts.sh"
source "$SRC_DIR/monitoring.sh"
source "$SRC_DIR/reports.sh"
source "$SRC_DIR/ui.sh"

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
    cleanup_temp_files
    
    exit 0
}

# Capturer les signaux
trap cleanup SIGINT SIGTERM

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
# POINT D'ENTRÉE
# =============================================================================

main "$@"