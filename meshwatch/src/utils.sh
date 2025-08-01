#!/bin/bash

# =============================================================================
# Module utilitaires
# =============================================================================

readonly LOG_FILE="$LOGS_DIR/meshwatch.log"

# =============================================================================
# FONCTIONS UTILITAIRES
# =============================================================================

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_level=$(get_config LOG_LEVEL)
    
    # Vérifier si le niveau de log est suffisant
    case "$log_level" in
        "DEBUG") local min_level=0 ;;
        "INFO")  local min_level=1 ;;
        "WARN")  local min_level=2 ;;
        "ERROR") local min_level=3 ;;
        *) local min_level=1 ;;
    esac
    
    case "$level" in
        "DEBUG") local msg_level=0 ;;
        "INFO")  local msg_level=1 ;;
        "WARN")  local msg_level=2 ;;
        "ERROR") local msg_level=3 ;;
        *) local msg_level=1 ;;
    esac
    
    # Ne pas logger si le niveau est insuffisant
    if (( msg_level < min_level )); then
        return
    fi
    
    # Journalisation dans fichier si activée
    if [[ "$(get_config LOGGING_ENABLED)" == "true" ]]; then
        # Vérifier rotation des logs
        rotate_logs
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi
    
    # Affichage console avec couleurs
    case "$level" in
        "ERROR") echo -e "${RED}[$(get_message "error")] $message${NC}" ;;
        "WARN")  echo -e "${YELLOW}[$(get_message "warning")] $message${NC}" ;;
        "INFO")  echo -e "${BLUE}[$(get_message "info")] $message${NC}" ;;
        "DEBUG") echo -e "${CYAN}[DEBUG] $message${NC}" ;;
        *) echo "$message" ;;
    esac
}

rotate_logs() {
    if [[ ! -f "$LOG_FILE" ]]; then
        return
    fi
    
    local log_size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
    local max_size=$((10 * 1024 * 1024))  # 10MB en bytes
    
    if (( log_size > max_size )); then
        # Garder les 5 dernières rotations
        for i in {4..1}; do
            if [[ -f "${LOG_FILE}.${i}" ]]; then
                mv "${LOG_FILE}.${i}" "${LOG_FILE}.$((i+1))"
            fi
        done
        
        mv "$LOG_FILE" "${LOG_FILE}.1"
        touch "$LOG_FILE"
        log_message "INFO" "Rotation des logs effectuée (taille: ${log_size} bytes)"
    fi
}

check_dependencies() {
    local missing_deps=()
    
    # Vérifier les commandes requises
    local required_commands=("ss" "curl" "ping" "netstat" "ip")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if (( ${#missing_deps[@]} > 0 )); then
        echo -e "${RED}Erreur: Dépendances manquantes: ${missing_deps[*]}${NC}" >&2
        echo "Installez les paquets manquants avec votre gestionnaire de paquets."
        exit 1
    fi
}

check_permissions() {
    # Vérifier si on peut écrire dans les répertoires nécessaires
    if [[ ! -w "$CONFIG_DIR" ]]; then
        echo -e "${RED}Erreur: Impossible d'écrire dans $CONFIG_DIR${NC}" >&2
        exit 1
    fi
    
    if [[ ! -w "$LOGS_DIR" ]]; then
        echo -e "${RED}Erreur: Impossible d'écrire dans $LOGS_DIR${NC}" >&2
        exit 1
    fi
    
    # Avertir si exécuté en tant que root
    if [[ $EUID -eq 0 ]]; then
        log_message "WARN" "Exécution en tant que root détectée"
    fi
}

cleanup_temp_files() {
    # Nettoyer les fichiers temporaires
    rm -f /tmp/meshwatch_stats_cache
    rm -f /tmp/meshwatch_interface_cache
    rm -rf /tmp/meshwatch_cooldowns
}

show_version() {
    echo "MeshWatch v$MESHWATCH_VERSION - Star Déception Edition"
    echo "Système de surveillance mesh pour Star Déception"
    echo "Architecture de serveurs maillés dynamiques"
    echo ""
    echo "Répertoires:"
    echo "  Script: $SCRIPT_DIR"
    echo "  Config: $CONFIG_DIR"
    echo "  Logs: $LOGS_DIR"
}

show_help() {
    cat << EOF
MeshWatch v$MESHWATCH_VERSION - Surveillance mesh pour Star Déception

Outil de monitoring spécialement conçu pour l'architecture de serveurs
maillés dynamiques du projet Star Déception.

UTILISATION:
    ./meshwatch.sh [OPTIONS]

OPTIONS:
    -h, --help      Afficher cette aide
    -v, --version   Afficher la version
    -c, --config    Afficher la configuration mesh
    -s, --status    Afficher le statut de surveillance

EXEMPLES:
    ./meshwatch.sh              # Interface interactive mesh
    ./meshwatch.sh --status     # Statut surveillance mesh
    ./meshwatch.sh --config     # Configuration Star Déception

FICHIERS:
    Configuration: $CONFIG_DIR/meshwatch.conf
    Logs: $LOGS_DIR/meshwatch.log
    PID: /tmp/meshwatch.pid

STAR DÉCEPTION:
    Ports mesh par défaut: 7777,7778,7779
    Orchestrateur: orchestrator.star-deception.com
    Discord: #mesh-monitoring

Pour plus d'informations: README.md
EOF
}

# Traitement des arguments de ligne de commande
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -c|--config)
                load_config
                show_configuration
                exit 0
                ;;
            -s|--status)
                load_config
                local status=$(get_monitoring_status)
                if [[ "$status" == "stopped" ]]; then
                    echo "MeshWatch: Arrêté"
                else
                    local pid=$(echo "$status" | cut -d: -f2)
                    local uptime=$(echo "$status" | cut -d: -f3)
                    echo "MeshWatch: En cours (PID: $pid, Uptime: $uptime)"
                fi
                exit 0
                ;;
            *)
                echo "Option inconnue: $1" >&2
                show_help
                exit 1
                ;;
        esac
        shift
    done
}