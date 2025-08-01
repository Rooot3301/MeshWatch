#!/bin/bash

# =============================================================================
# MeshWatch - Surveillance dynamique des flux sortants d'un serveur de jeu
# =============================================================================
# Auteur: Assistant IA
# Version: 1.0
# Description: Système de monitoring réseau avec alertes Discord
# =============================================================================

# Variables globales
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="$HOME/.meshwatch.conf"
readonly PID_FILE="/tmp/meshwatch.pid"
readonly LOG_FILE="/var/log/meshwatch.log"

# Couleurs pour l'affichage
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Variables de configuration par défaut
DEFAULT_PORTS="7777,27015,25565"
DEFAULT_ORCHESTRATOR_HOST="orchestrator.example.com"
DEFAULT_DISCORD_WEBHOOK=""
DEFAULT_MONITORING_ENABLED="false"
DEFAULT_LOGGING_ENABLED="true"
DEFAULT_LANG="fr"
DEFAULT_ALERT_TIMEOUT=120
DEFAULT_MAX_CONN=50
DEFAULT_MAX_BANDWIDTH_MBPS=100
DEFAULT_INTERFACE=""
DEFAULT_ALERT_COOLDOWN=300
DEFAULT_LOG_ROTATION_SIZE="10M"

# Variables de langue
declare -A MESSAGES_FR=(
    ["menu_title"]="=== MeshWatch - Surveillance Réseau ==="
    ["menu_start"]="Démarrer la surveillance"
    ["menu_stop"]="Arrêter la surveillance"
    ["menu_config_ports"]="Configurer les ports"
    ["menu_config_webhook"]="Configurer webhook Discord"
    ["menu_toggle_logging"]="Basculer journalisation"
    ["menu_live_view"]="Voir flux en direct"
    ["menu_show_config"]="Afficher configuration"
    ["menu_change_lang"]="Changer de langue"
    ["menu_quit"]="Quitter"
    ["monitoring_started"]="Surveillance démarrée"
    ["monitoring_stopped"]="Surveillance arrêtée"
    ["monitoring_already_running"]="Surveillance déjà en cours"
    ["monitoring_not_running"]="Surveillance non active"
    ["config_saved"]="Configuration sauvegardée"
    ["enter_ports"]="Entrez les ports (ex: 7777,27015 ou 7000-8000):"
    ["enter_webhook"]="Entrez l'URL du webhook Discord:"
    ["enter_orchestrator"]="Entrez l'hôte orchestrateur:"
    ["logging_enabled"]="Journalisation activée"
    ["logging_disabled"]="Journalisation désactivée"
    ["press_enter"]="Appuyez sur Entrée pour continuer..."
    ["invalid_choice"]="Choix invalide"
    ["error"]="Erreur"
    ["warning"]="Attention"
    ["info"]="Info"
    ["status_running"]="En cours"
    ["status_stopped"]="Arrêté"
    ["connections"]="Connexions"
    ["bandwidth"]="Débit"
    ["alert_high_bandwidth"]="Débit élevé détecté"
    ["alert_high_connections"]="Trop de connexions"
    ["alert_no_outbound"]="Absence de flux sortant"
    ["alert_orchestrator_timeout"]="Timeout orchestrateur"
)

declare -A MESSAGES_EN=(
    ["menu_title"]="=== MeshWatch - Network Monitoring ==="
    ["menu_start"]="Start monitoring"
    ["menu_stop"]="Stop monitoring"
    ["menu_config_ports"]="Configure ports"
    ["menu_config_webhook"]="Configure Discord webhook"
    ["menu_toggle_logging"]="Toggle logging"
    ["menu_live_view"]="View live flows"
    ["menu_show_config"]="Show configuration"
    ["menu_change_lang"]="Change language"
    ["menu_quit"]="Quit"
    ["monitoring_started"]="Monitoring started"
    ["monitoring_stopped"]="Monitoring stopped"
    ["monitoring_already_running"]="Monitoring already running"
    ["monitoring_not_running"]="Monitoring not active"
    ["config_saved"]="Configuration saved"
    ["enter_ports"]="Enter ports (ex: 7777,27015 or 7000-8000):"
    ["enter_webhook"]="Enter Discord webhook URL:"
    ["enter_orchestrator"]="Enter orchestrator host:"
    ["logging_enabled"]="Logging enabled"
    ["logging_disabled"]="Logging disabled"
    ["press_enter"]="Press Enter to continue..."
    ["invalid_choice"]="Invalid choice"
    ["error"]="Error"
    ["warning"]="Warning"
    ["info"]="Info"
    ["status_running"]="Running"
    ["status_stopped"]="Stopped"
    ["connections"]="Connections"
    ["bandwidth"]="Bandwidth"
    ["alert_high_bandwidth"]="High bandwidth detected"
    ["alert_high_connections"]="Too many connections"
    ["alert_no_outbound"]="No outbound traffic"
    ["alert_orchestrator_timeout"]="Orchestrator timeout"
)

# =============================================================================
# FONCTIONS UTILITAIRES
# =============================================================================

# Fonction pour auto-détecter l'interface réseau principale
detect_network_interface() {
    # Chercher l'interface avec une route par défaut
    local interface=$(ip route | grep '^default' | head -1 | awk '{print $5}')
    
    # Si pas trouvé, chercher la première interface active (pas lo)
    if [[ -z "$interface" ]]; then
        interface=$(ip link show | grep -E '^[0-9]+:' | grep -v 'lo:' | head -1 | cut -d: -f2 | tr -d ' ')
    fi
    
    # Fallback sur eth0
    echo "${interface:-eth0}"
}

# Fonction pour valider le format des ports
validate_ports() {
    local ports="$1"
    
    # Vérifier format: ports séparés par virgules ou plages
    if [[ ! "$ports" =~ ^[0-9,:-]+$ ]]; then
        return 1
    fi
    
    # Vérifier chaque port/plage
    IFS=',' read -ra PORT_ARRAY <<< "$ports"
    for port in "${PORT_ARRAY[@]}"; do
        if [[ "$port" =~ ^[0-9]+-[0-9]+$ ]]; then
            # Plage de ports
            local start_port=$(echo "$port" | cut -d- -f1)
            local end_port=$(echo "$port" | cut -d- -f2)
            if (( start_port < 1 || start_port > 65535 || end_port < 1 || end_port > 65535 || start_port > end_port )); then
                return 1
            fi
        elif [[ "$port" =~ ^[0-9]+$ ]]; then
            # Port simple
            if (( port < 1 || port > 65535 )); then
                return 1
            fi
        else
            return 1
        fi
    done
    
    return 0
}

# Fonction pour la rotation des logs
rotate_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        local log_size=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
        local max_size=$((10 * 1024 * 1024))  # 10MB en bytes
        
        if (( log_size > max_size )); then
            mv "$LOG_FILE" "${LOG_FILE}.old"
            touch "$LOG_FILE"
            log_message "INFO" "Rotation des logs effectuée (taille: ${log_size} bytes)"
        fi
    fi
}

# Fonction pour vérifier le cooldown des alertes
check_alert_cooldown() {
    local alert_type="$1"
    local cooldown_file="/tmp/meshwatch_cooldown_${alert_type}"
    local current_time=$(date +%s)
    
    if [[ -f "$cooldown_file" ]]; then
        local last_alert=$(cat "$cooldown_file")
        local time_diff=$((current_time - last_alert))
        
        if (( time_diff < ALERT_COOLDOWN )); then
            return 1  # Encore en cooldown
        fi
    fi
    
    echo "$current_time" > "$cooldown_file"
    return 0  # Peut envoyer l'alerte
}
# Fonction pour charger la configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        # Créer configuration par défaut
        PORTS="$DEFAULT_PORTS"
        ORCHESTRATOR_HOST="$DEFAULT_ORCHESTRATOR_HOST"
        DISCORD_WEBHOOK="$DEFAULT_DISCORD_WEBHOOK"
        MONITORING_ENABLED="$DEFAULT_MONITORING_ENABLED"
        LOGGING_ENABLED="$DEFAULT_LOGGING_ENABLED"
        LANG="$DEFAULT_LANG"
        ALERT_TIMEOUT="$DEFAULT_ALERT_TIMEOUT"
        MAX_CONN="$DEFAULT_MAX_CONN"
        MAX_BANDWIDTH_MBPS="$DEFAULT_MAX_BANDWIDTH_MBPS"
        INTERFACE="${DEFAULT_INTERFACE:-$(detect_network_interface)}"
        ALERT_COOLDOWN="$DEFAULT_ALERT_COOLDOWN"
        LOG_ROTATION_SIZE="$DEFAULT_LOG_ROTATION_SIZE"
        save_config
    fi
    
    # Auto-détecter l'interface si vide
    if [[ -z "$INTERFACE" ]]; then
        INTERFACE=$(detect_network_interface)
    fi
}

# Fonction pour sauvegarder la configuration
save_config() {
    cat > "$CONFIG_FILE" << EOF
# Configuration MeshWatch
PORTS="$PORTS"
ORCHESTRATOR_HOST="$ORCHESTRATOR_HOST"
DISCORD_WEBHOOK="$DISCORD_WEBHOOK"
MONITORING_ENABLED="$MONITORING_ENABLED"
LOGGING_ENABLED="$LOGGING_ENABLED"
LANG="$LANG"
ALERT_TIMEOUT="$ALERT_TIMEOUT"
MAX_CONN="$MAX_CONN"
MAX_BANDWIDTH_MBPS="$MAX_BANDWIDTH_MBPS"
INTERFACE="$INTERFACE"
ALERT_COOLDOWN="$ALERT_COOLDOWN"
LOG_ROTATION_SIZE="$LOG_ROTATION_SIZE"
EOF
    echo -e "${GREEN}$(get_message "config_saved")${NC}"
}

# Fonction pour obtenir un message traduit
get_message() {
    local key="$1"
    if [[ "$LANG" == "en" ]]; then
        echo "${MESSAGES_EN[$key]}"
    else
        echo "${MESSAGES_FR[$key]}"
    fi
}

# Fonction de logging
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ "$LOGGING_ENABLED" == "true" ]]; then
        # Vérifier rotation des logs
        rotate_logs
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi
    
    case "$level" in
        "ERROR") echo -e "${RED}[$(get_message "error")] $message${NC}" ;;
        "WARN") echo -e "${YELLOW}[$(get_message "warning")] $message${NC}" ;;
        "INFO") echo -e "${BLUE}[$(get_message "info")] $message${NC}" ;;
        *) echo "$message" ;;
    esac
}

# Fonction pour envoyer une alerte Discord
send_discord_alert() {
    local title="$1"
    local description="$2"
    local color="$3"
    
    if [[ -z "$DISCORD_WEBHOOK" ]]; then
        return
    fi
    
    local payload=$(cat << EOF
{
    "embeds": [{
        "title": "$title",
        "description": "$description",
        "color": $color,
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
        "footer": {
            "text": "MeshWatch Alert System"
        }
    }]
}
EOF
)
    
    curl -H "Content-Type: application/json" \
         -X POST \
         -d "$payload" \
         "$DISCORD_WEBHOOK" \
         --silent --output /dev/null
}

# Fonction pour vérifier si le monitoring est actif
is_monitoring_active() {
    [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

# Fonction pour obtenir les statistiques réseau
get_network_stats() {
    local interface="${1:-$INTERFACE}"
    
    # Construire la liste des ports pour ss
    local port_list=""
    IFS=',' read -ra PORT_ARRAY <<< "$PORTS"
    for port in "${PORT_ARRAY[@]}"; do
        if [[ "$port" =~ ^[0-9]+-[0-9]+$ ]]; then
            # Plage de ports - développer en ports individuels
            local start_port=$(echo "$port" | cut -d- -f1)
            local end_port=$(echo "$port" | cut -d- -f2)
            for ((p=start_port; p<=end_port; p++)); do
                if [[ -n "$port_list" ]]; then
                    port_list="$port_list,$p"
                else
                    port_list="$p"
                fi
            done
        else
            # Port simple
            if [[ -n "$port_list" ]]; then
                port_list="$port_list,$port"
            else
                port_list="$port"
            fi
        fi
    done
    
    # Compter les connexions sur les ports configurés
    local connections=0
    if [[ -n "$port_list" ]]; then
        # Utiliser une approche plus simple avec grep
        connections=$(ss -tuln 2>/dev/null | grep -E ":($port_list)" | wc -l)
    fi
    
    # Cache des statistiques pour éviter lectures multiples
    if [[ ! -f "/tmp/meshwatch_stats_cache" ]] || [[ $(($(date +%s) - $(stat -c %Y /tmp/meshwatch_stats_cache 2>/dev/null || echo 0))) -gt 2 ]]; then
        local net_stats=$(grep "$interface" /proc/net/dev)
        local rx_bytes=$(echo "$net_stats" | awk '{print $2}')
        local tx_bytes=$(echo "$net_stats" | awk '{print $10}')
        echo "$connections:$rx_bytes:$tx_bytes:$(date +%s)" > /tmp/meshwatch_stats_cache
    fi
    
    cat /tmp/meshwatch_stats_cache
}

# Fonction pour détecter les anomalies
detect_anomalies() {
    local connections="$1"
    local bandwidth_mbps="$2"
    local orchestrator_status="$3"
    
    # Vérifier le nombre de connexions
    if (( connections > MAX_CONN )); then
        if check_alert_cooldown "high_connections"; then
            log_message "WARN" "$(get_message "alert_high_connections"): $connections"
            send_discord_alert "⚠️ $(get_message "alert_high_connections")" \
                              "$(get_message "connections"): $connections/$MAX_CONN" \
                              16776960  # Orange
        fi
    fi
    
    # Vérifier le débit
    if (( bandwidth_mbps > MAX_BANDWIDTH_MBPS )); then
        if check_alert_cooldown "high_bandwidth"; then
            log_message "WARN" "$(get_message "alert_high_bandwidth"): ${bandwidth_mbps}Mbps"
            send_discord_alert "⚠️ $(get_message "alert_high_bandwidth")" \
                              "$(get_message "bandwidth"): ${bandwidth_mbps}Mbps/${MAX_BANDWIDTH_MBPS}Mbps" \
                              16711680  # Rouge
        fi
    fi
    
    # Vérifier l'orchestrateur
    if [[ "$orchestrator_status" == "timeout" ]]; then
        if check_alert_cooldown "orchestrator_timeout"; then
            log_message "ERROR" "$(get_message "alert_orchestrator_timeout")"
            send_discord_alert "🔴 $(get_message "alert_orchestrator_timeout")" \
                              "Host: $ORCHESTRATOR_HOST" \
                              16711680  # Rouge
        fi
    fi
}

# =============================================================================
# FONCTIONS DE MONITORING
# =============================================================================

# Fonction principale de monitoring
start_monitoring_daemon() {
    if is_monitoring_active; then
        log_message "WARN" "$(get_message "monitoring_already_running")"
        return 1
    fi
    
    log_message "INFO" "$(get_message "monitoring_started")"
    
    # Démarrer le daemon en arrière-plan
    (
        echo $$ > "$PID_FILE"
        local prev_stats=""
        
        while true; do
            # Obtenir les statistiques réseau
            local current_stats=$(get_network_stats)
            local connections=$(echo "$current_stats" | cut -d: -f1)
            local rx_bytes=$(echo "$current_stats" | cut -d: -f2)
            local tx_bytes=$(echo "$current_stats" | cut -d: -f3)
            
            # Calculer le débit si nous avons des statistiques précédentes
            local bandwidth_mbps=0
            if [[ -n "$prev_stats" ]]; then
                local prev_tx=$(echo "$prev_stats" | cut -d: -f3)
                local diff_bytes=$((tx_bytes - prev_tx))
                bandwidth_mbps=$((diff_bytes * 8 / 1024 / 1024))  # Convertir en Mbps
            fi
            
            # Vérifier l'orchestrateur
            local orchestrator_status="ok"
            if ! timeout 5 ping -c 1 "$ORCHESTRATOR_HOST" >/dev/null 2>&1; then
                orchestrator_status="timeout"
            fi
            
            # Détecter les anomalies
            detect_anomalies "$connections" "$bandwidth_mbps" "$orchestrator_status"
            
            prev_stats="$current_stats"
            sleep "$ALERT_TIMEOUT"
        done
    ) &
    
    MONITORING_ENABLED="true"
    save_config
}

# Fonction pour arrêter le monitoring
stop_monitoring() {
    if ! is_monitoring_active; then
        log_message "WARN" "$(get_message "monitoring_not_running")"
        return 1
    fi
    
    local pid=$(cat "$PID_FILE")
    kill "$pid" 2>/dev/null
    rm -f "$PID_FILE"
    
    MONITORING_ENABLED="false"
    save_config
    
    log_message "INFO" "$(get_message "monitoring_stopped")"
}

# Fonction pour afficher les flux en direct
show_live_flows() {
    echo -e "${CYAN}=== Flux réseau en direct ===${NC}"
    echo -e "${YELLOW}Appuyez sur Ctrl+C pour arrêter${NC}"
    echo ""
    
    # Fonction locale pour gérer Ctrl+C dans cette vue seulement
    local_cleanup() {
        echo ""
        echo -e "${GREEN}Retour au menu principal...${NC}"
        return 0
    }
    
    # Temporairement remplacer le gestionnaire de signal
    trap local_cleanup SIGINT
    
    # Utiliser ss pour afficher les connexions en temps réel
    while true; do
        clear
        echo -e "${CYAN}=== Flux réseau en direct - $(date) ===${NC}"
        echo ""
        
        # Afficher les connexions sortantes sur les ports configurés
        echo -e "${WHITE}Connexions sortantes:${NC}"
        ss -tuln | grep -E ":($PORTS)" | head -20 || echo "Aucune connexion détectée"
        
        echo ""
        echo -e "${WHITE}Statistiques interface réseau:${NC}"
        cat /proc/net/dev | grep -E "(eth0|ens|enp)" | head -3
        
        echo ""
        echo -e "${WHITE}Top processus réseau:${NC}"
        netstat -tulpn 2>/dev/null | grep -E ":($PORTS)" | head -10 || echo "Aucun processus détecté"
        
        sleep 2 || break  # Sortir de la boucle si interrompu
    done
    
    # Restaurer le gestionnaire de signal original
    trap cleanup SIGINT SIGTERM
}

# =============================================================================
# FONCTIONS D'INTERFACE
# =============================================================================

# Fonction pour configurer les ports
configure_ports() {
    echo -e "${YELLOW}$(get_message "enter_ports")${NC}"
    echo -e "${BLUE}Ports actuels: $PORTS${NC}"
    read -r new_ports
    
    if [[ -n "$new_ports" ]]; then
        PORTS="$new_ports"
        save_config
    fi
}

# Fonction pour configurer le webhook Discord
configure_webhook() {
    echo -e "${YELLOW}$(get_message "enter_webhook")${NC}"
    echo -e "${BLUE}Webhook actuel: ${DISCORD_WEBHOOK:-"Non configuré"}${NC}"
    read -r new_webhook
    
    if [[ -n "$new_webhook" ]]; then
        DISCORD_WEBHOOK="$new_webhook"
        save_config
    fi
}

# Fonction pour configurer l'orchestrateur
configure_orchestrator() {
    echo -e "${YELLOW}$(get_message "enter_orchestrator")${NC}"
    echo -e "${BLUE}Orchestrateur actuel: $ORCHESTRATOR_HOST${NC}"
    read -r new_orchestrator
    
    if [[ -n "$new_orchestrator" ]]; then
        ORCHESTRATOR_HOST="$new_orchestrator"
        save_config
    fi
}

# Fonction pour basculer la journalisation
toggle_logging() {
    if [[ "$LOGGING_ENABLED" == "true" ]]; then
        LOGGING_ENABLED="false"
        echo -e "${YELLOW}$(get_message "logging_disabled")${NC}"
    else
        LOGGING_ENABLED="true"
        echo -e "${GREEN}$(get_message "logging_enabled")${NC}"
    fi
    save_config
}

# Fonction pour changer de langue
change_language() {
    if [[ "$LANG" == "fr" ]]; then
        LANG="en"
    else
        LANG="fr"
    fi
    save_config
    echo -e "${GREEN}Language changed to: $LANG${NC}"
}

# Fonction pour afficher la configuration
show_configuration() {
    clear
    echo -e "${PURPLE}=== Configuration MeshWatch ===${NC}"
    echo ""
    echo -e "${WHITE}Ports surveillés:${NC} $PORTS"
    echo -e "${WHITE}Orchestrateur:${NC} $ORCHESTRATOR_HOST"
    echo -e "${WHITE}Webhook Discord:${NC} ${DISCORD_WEBHOOK:-"Non configuré"}"
    echo -e "${WHITE}Monitoring:${NC} $([ "$MONITORING_ENABLED" == "true" ] && echo "$(get_message "status_running")" || echo "$(get_message "status_stopped")")"
    echo -e "${WHITE}Journalisation:${NC} $([ "$LOGGING_ENABLED" == "true" ] && echo "Activée" || echo "Désactivée")"
    echo -e "${WHITE}Langue:${NC} $LANG"
    echo -e "${WHITE}Timeout alerte:${NC} ${ALERT_TIMEOUT}s"
    echo -e "${WHITE}Connexions max:${NC} $MAX_CONN"
    echo -e "${WHITE}Débit max:${NC} ${MAX_BANDWIDTH_MBPS}Mbps"
    echo ""
    echo -e "${WHITE}Fichier de configuration:${NC} $CONFIG_FILE"
    echo -e "${WHITE}Fichier de log:${NC} $LOG_FILE"
    echo -e "${WHITE}Fichier PID:${NC} $PID_FILE"
    echo ""
}

# Fonction du menu principal
show_menu() {
    clear
    echo -e "${PURPLE}"
    cat << 'EOF'
███╗   ███╗███████╗███████╗██╗  ██╗██╗    ██╗ █████╗ ████████╗ ██████╗██╗  ██╗███████╗██████╗ 
████╗ ████║██╔════╝██╔════╝██║  ██║██║    ██║██╔══██╗╚══██╔══╝██╔════╝██║  ██║██╔════╝██╔══██╗
██╔████╔██║█████╗  ███████╗███████║██║ █╗ ██║███████║   ██║   ██║     ███████║███████╗██║  ██║
██║╚██╔╝██║██╔══╝  ╚════██║██╔══██║██║███╗██║██╔══██║   ██║   ██║     ██╔══██║╚════██║██║  ██║
██║ ╚═╝ ██║███████╗███████║██║  ██║╚███╔███╔╝██║  ██║   ██║   ╚██████╗██║  ██║███████║██████╔╝
╚═╝     ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝╚══════╝╚═════╝
EOF
    echo -e "${NC}"
    echo -e "${PURPLE}$(get_message "menu_title")${NC}"
    echo ""
    
    # Afficher le statut
    local status_color="${RED}"
    local status_text="$(get_message "status_stopped")"
    if is_monitoring_active; then
        status_color="${GREEN}"
        status_text="$(get_message "status_running")"
    fi
    echo -e "${WHITE}Statut:${NC} ${status_color}$status_text${NC}"
    echo ""
    
    echo "1) $(get_message "menu_start")"
    echo "2) $(get_message "menu_stop")"
    echo "3) $(get_message "menu_config_ports")"
    echo "4) $(get_message "menu_config_webhook")"
    echo "5) $(get_message "menu_toggle_logging")"
    echo "6) $(get_message "menu_live_view")"
    echo "7) $(get_message "menu_show_config")"
    echo "8) $(get_message "menu_change_lang")"
    echo "9) Configuration avancée"
    echo "10) $(get_message "menu_quit")"
    echo ""
    echo -n "Choix: "
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

main() {
    # Vérifier les permissions
    if [[ $EUID -eq 0 ]]; then
        log_message "WARN" "Exécution en tant que root détectée"
    fi
    
    # Charger la configuration
    load_config
    
    # Boucle principale du menu
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1)
                start_monitoring_daemon
                read -p "$(get_message "press_enter")" -r
                ;;
            2)
                stop_monitoring
                read -p "$(get_message "press_enter")" -r
                ;;
            3)
                configure_ports
                read -p "$(get_message "press_enter")" -r
                ;;
            4)
                configure_webhook
                read -p "$(get_message "press_enter")" -r
                ;;
            5)
                toggle_logging
                read -p "$(get_message "press_enter")" -r
                ;;
            6)
                show_live_flows
                ;;
            7)
                show_configuration
                read -p "$(get_message "press_enter")" -r
                ;;
            8)
                change_language
                read -p "$(get_message "press_enter")" -r
                ;;
            9)
                advanced_config_menu
                ;;
            10)
                echo -e "${GREEN}Au revoir!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}$(get_message "invalid_choice")${NC}"
                read -p "$(get_message "press_enter")" -r
                ;;
        esac
    done
}

# =============================================================================
# GESTION DES SIGNAUX ET NETTOYAGE
# =============================================================================

cleanup() {
    echo ""
    log_message "INFO" "Arrêt du script MeshWatch"
    stop_monitoring
    exit 0
}

# Capturer les signaux pour un arrêt propre
trap cleanup SIGINT SIGTERM

# =============================================================================
# POINT D'ENTRÉE
# =============================================================================

# Vérifier les dépendances
command -v ss >/dev/null 2>&1 || { echo "Erreur: ss n'est pas installé" >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "Erreur: curl n'est pas installé" >&2; exit 1; }

# Démarrer l'application
main "$@"