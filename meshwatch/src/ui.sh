#!/bin/bash

# =============================================================================
# Module d'interface utilisateur
# =============================================================================

# Couleurs pour l'affichage
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Messages multilingues
declare -A MESSAGES_FR=(
    ["menu_title"]="=== MeshWatch Star Déception - Surveillance Mesh ==="
    ["menu_start"]="Démarrer surveillance mesh"
    ["menu_stop"]="Arrêter surveillance mesh"
    ["menu_config_ports"]="Configurer ports mesh"
    ["menu_config_webhook"]="Configurer alertes Discord"
    ["menu_toggle_logging"]="Basculer journalisation"
    ["menu_live_view"]="Voir flux mesh en direct"
    ["menu_show_config"]="Afficher configuration"
    ["menu_change_lang"]="Changer de langue"
    ["menu_advanced"]="Configuration avancée"
    ["menu_quit"]="Quitter"
    ["monitoring_started"]="Surveillance mesh démarrée"
    ["monitoring_stopped"]="Surveillance mesh arrêtée"
    ["monitoring_already_running"]="Surveillance mesh déjà active"
    ["monitoring_not_running"]="Surveillance mesh inactive"
    ["config_saved"]="Configuration sauvegardée"
    ["enter_ports"]="Ports mesh Star Déception (ex: 7777,7778 ou 7000-8000):"
    ["enter_webhook"]="Webhook Discord (#mesh-monitoring):"
    ["enter_orchestrator"]="Orchestrateur Star Déception:"
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
    ["webhook_test_success"]="Test webhook réussi"
    ["webhook_test_failed"]="Test webhook échoué"
    ["invalid_webhook"]="URL webhook invalide"
    ["invalid_ports"]="Format de ports invalide"
)

declare -A MESSAGES_EN=(
    ["menu_title"]="=== MeshWatch Star Deception - Mesh Monitoring ==="
    ["menu_start"]="Start mesh monitoring"
    ["menu_stop"]="Stop mesh monitoring"
    ["menu_config_ports"]="Configure mesh ports"
    ["menu_config_webhook"]="Configure Discord alerts"
    ["menu_toggle_logging"]="Toggle logging"
    ["menu_live_view"]="View live mesh flows"
    ["menu_show_config"]="Show configuration"
    ["menu_change_lang"]="Change language"
    ["menu_advanced"]="Advanced configuration"
    ["menu_quit"]="Quit"
    ["monitoring_started"]="Mesh monitoring started"
    ["monitoring_stopped"]="Mesh monitoring stopped"
    ["monitoring_already_running"]="Mesh monitoring already active"
    ["monitoring_not_running"]="Mesh monitoring inactive"
    ["config_saved"]="Configuration saved"
    ["enter_ports"]="Star Deception mesh ports (ex: 7777,7778 or 7000-8000):"
    ["enter_webhook"]="Discord webhook (#mesh-monitoring):"
    ["enter_orchestrator"]="Star Deception orchestrator:"
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
    ["webhook_test_success"]="Webhook test successful"
    ["webhook_test_failed"]="Webhook test failed"
    ["invalid_webhook"]="Invalid webhook URL"
    ["invalid_ports"]="Invalid ports format"
)

# =============================================================================
# FONCTIONS D'INTERFACE
# =============================================================================

get_message() {
    local key="$1"
    local lang=$(get_config LANG)
    
    if [[ "$lang" == "en" ]]; then
        echo "${MESSAGES_EN[$key]:-$key}"
    else
        echo "${MESSAGES_FR[$key]:-$key}"
    fi
}

show_ascii_art() {
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
}

show_menu() {
    clear
    show_ascii_art
    echo -e "${PURPLE}$(get_message "menu_title")${NC}"
    echo -e "${CYAN}Version $MESHWATCH_VERSION - Build $BUILD_DATE${NC}"
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
    
    echo "1)  $(get_message "menu_start")"
    echo "2)  $(get_message "menu_stop")"
    echo "3)  $(get_message "menu_config_ports")"
    echo "4)  $(get_message "menu_config_webhook")"
    echo "5)  $(get_message "menu_toggle_logging")"
    echo "6)  $(get_message "menu_live_view")"
    echo "7)  $(get_message "menu_show_config")"
    echo "8)  $(get_message "menu_change_lang")"
    echo "9)  $(get_message "menu_advanced")"
    echo "10) Mettre à jour MeshWatch"
    echo "11) Informations version"
    echo "12) $(get_message "menu_quit")"
    echo ""
    echo -n "Choix: "
}

configure_ports() {
    echo -e "${YELLOW}$(get_message "enter_ports")${NC}"
    echo -e "${BLUE}Ports mesh actuels: $(get_config PORTS)${NC}"
    echo -e "${CYAN}Exemples Star Déception: 7777,7778,7779 ou 7000-8000 ou 7777,7780-7790${NC}"
    read -r new_ports
    
    if [[ -n "$new_ports" ]]; then
        if validate_ports "$new_ports"; then
            set_config "PORTS" "$new_ports"
            save_config
            echo -e "${GREEN}$(get_message "config_saved")${NC}"
        else
            echo -e "${RED}$(get_message "invalid_ports")${NC}"
        fi
    fi
}

configure_webhook() {
    echo -e "${YELLOW}$(get_message "enter_webhook")${NC}"
    echo -e "${BLUE}Webhook Discord actuel: ${DISCORD_WEBHOOK:-"Non configuré"}${NC}"
    echo -e "${CYAN}Canal recommandé: #mesh-monitoring${NC}"
    echo -e "${CYAN}Format: https://discord.com/api/webhooks/STAR_DECEPTION_ID/TOKEN${NC}"
    read -r new_webhook
    
    if [[ -n "$new_webhook" ]]; then
        if validate_webhook "$new_webhook"; then
            echo -e "${BLUE}Test du webhook...${NC}"
            if test_discord_webhook "$new_webhook"; then
                set_config "DISCORD_WEBHOOK" "$new_webhook"
                save_config
                echo -e "${GREEN}$(get_message "webhook_test_success")${NC}"
            else
                echo -e "${RED}$(get_message "webhook_test_failed")${NC}"
            fi
        else
            echo -e "${RED}$(get_message "invalid_webhook")${NC}"
        fi
    fi
}

toggle_logging() {
    local current=$(get_config LOGGING_ENABLED)
    if [[ "$current" == "true" ]]; then
        set_config "LOGGING_ENABLED" "false"
        echo -e "${YELLOW}$(get_message "logging_disabled")${NC}"
    else
        set_config "LOGGING_ENABLED" "true"
        echo -e "${GREEN}$(get_message "logging_enabled")${NC}"
    fi
    save_config
}

change_language() {
    local current=$(get_config LANG)
    if [[ "$current" == "fr" ]]; then
        set_config "LANG" "en"
        echo -e "${GREEN}Language changed to: English${NC}"
    else
        set_config "LANG" "fr"
        echo -e "${GREEN}Langue changée vers: Français${NC}"
    fi
    save_config
}

show_configuration() {
    clear
    echo -e "${PURPLE}=== Configuration MeshWatch Star Déception ===${NC}"
    echo ""
    echo -e "${WHITE}Ports mesh:${NC} $(get_config PORTS)"
    echo -e "${WHITE}Orchestrateur Star Déception:${NC} $(get_config ORCHESTRATOR_HOST)"
    echo -e "${WHITE}Discord (#mesh-monitoring):${NC} $(get_config DISCORD_WEBHOOK | sed 's/\(.*\/\).*/\1***/')"
    echo -e "${WHITE}Surveillance mesh:${NC} $(get_config MONITORING_ENABLED)"
    echo -e "${WHITE}Journalisation:${NC} $(get_config LOGGING_ENABLED)"
    echo -e "${WHITE}Langue:${NC} $(get_config LANG)"
    echo -e "${WHITE}Interface mesh:${NC} $(get_config INTERFACE)"
    echo -e "${WHITE}Timeout alerte:${NC} $(get_config ALERT_TIMEOUT)s"
    echo -e "${WHITE}Connexions mesh max:${NC} $(get_config MAX_CONN)"
    echo -e "${WHITE}Débit mesh max:${NC} $(get_config MAX_BANDWIDTH_MBPS)Mbps"
    echo -e "${WHITE}Cooldown alertes:${NC} $(get_config ALERT_COOLDOWN)s"
    echo ""
    echo -e "${WHITE}Fichiers:${NC}"
    echo -e "  Config: $CONFIG_FILE"
    echo -e "  Logs: $LOGS_DIR/meshwatch.log"
    echo -e "  PID: /tmp/meshwatch.pid"
    echo ""
}

show_live_flows() {
    echo -e "${CYAN}=== Flux mesh Star Déception en direct ===${NC}"
    echo -e "${YELLOW}Appuyez sur Ctrl+C pour revenir au menu${NC}"
    echo ""
    
    # Gestionnaire local pour Ctrl+C
    local_cleanup() {
        echo ""
        echo -e "${GREEN}Retour au menu principal...${NC}"
        return 0
    }
    
    # Remplacer temporairement le gestionnaire de signal
    trap local_cleanup SIGINT
    
    while true; do
        clear
        echo -e "${CYAN}=== Flux mesh Star Déception - $(date '+%H:%M:%S') ===${NC}"
        echo ""
        
        # Statistiques actuelles
        local stats=$(get_network_stats)
        local connections=$(echo "$stats" | cut -d: -f1)
        local interface=$(get_config INTERFACE)
        
        echo -e "${WHITE}Interface Mesh: $interface | Connexions inter-serveurs: $connections${NC}"
        echo ""
        
        # Connexions actives
        echo -e "${WHITE}Connexions mesh actives:${NC}"
        get_active_connections | head -10 || echo "Aucune connexion mesh détectée"
        
        echo ""
        echo -e "${WHITE}Processus Star Déception:${NC}"
        get_network_processes | head -5 || echo "Aucun processus mesh détecté"
        
        sleep 2 || break
    done
    
    # Restaurer le gestionnaire de signal original
    trap cleanup SIGINT SIGTERM
}

advanced_config_menu() {
    while true; do
        clear
        echo -e "${PURPLE}=== Configuration Avancée ===${NC}"
        echo ""
        echo "1) Configurer orchestrateur ($(get_config ORCHESTRATOR_HOST))"
        echo "2) Seuil connexions max ($(get_config MAX_CONN))"
        echo "3) Seuil débit max ($(get_config MAX_BANDWIDTH_MBPS) Mbps)"
        echo "4) Timeout alertes ($(get_config ALERT_TIMEOUT)s)"
        echo "5) Cooldown alertes ($(get_config ALERT_COOLDOWN)s)"
        echo "6) Interface réseau ($(get_config INTERFACE))"
        echo "7) Niveau de log ($(get_config LOG_LEVEL))"
        echo "8) Retour au menu principal"
        echo ""
        echo -n "Choix: "
        
        read -r choice
        case $choice in
            1) configure_orchestrator ;;
            2) configure_max_connections ;;
            3) configure_max_bandwidth ;;
            4) configure_alert_timeout ;;
            5) configure_alert_cooldown ;;
            6) configure_interface ;;
            7) configure_log_level ;;
            8) break ;;
            *) echo -e "${RED}$(get_message "invalid_choice")${NC}" ;;
        esac
        
        if [[ $choice != 8 ]]; then
            read -p "$(get_message "press_enter")" -r
        fi
    done
}

configure_orchestrator() {
    echo -e "${YELLOW}$(get_message "enter_orchestrator")${NC}"
    echo -e "${BLUE}Orchestrateur actuel: $(get_config ORCHESTRATOR_HOST)${NC}"
    read -r new_orchestrator
    
    if [[ -n "$new_orchestrator" ]]; then
        set_config "ORCHESTRATOR_HOST" "$new_orchestrator"
        save_config
    fi
}

configure_max_connections() {
    echo -e "${YELLOW}Entrez le nombre maximum de connexions:${NC}"
    echo -e "${BLUE}Valeur actuelle: $(get_config MAX_CONN)${NC}"
    read -r new_max
    
    if [[ "$new_max" =~ ^[0-9]+$ ]] && (( new_max > 0 )); then
        set_config "MAX_CONN" "$new_max"
        save_config
    else
        echo -e "${RED}Valeur invalide${NC}"
    fi
}

configure_max_bandwidth() {
    echo -e "${YELLOW}Entrez le débit maximum (Mbps):${NC}"
    echo -e "${BLUE}Valeur actuelle: $(get_config MAX_BANDWIDTH_MBPS)${NC}"
    read -r new_max
    
    if [[ "$new_max" =~ ^[0-9]+$ ]] && (( new_max > 0 )); then
        set_config "MAX_BANDWIDTH_MBPS" "$new_max"
        save_config
    else
        echo -e "${RED}Valeur invalide${NC}"
    fi
}

configure_alert_timeout() {
    echo -e "${YELLOW}Entrez le timeout entre alertes (secondes):${NC}"
    echo -e "${BLUE}Valeur actuelle: $(get_config ALERT_TIMEOUT)${NC}"
    read -r new_timeout
    
    if [[ "$new_timeout" =~ ^[0-9]+$ ]] && (( new_timeout >= 30 )); then
        set_config "ALERT_TIMEOUT" "$new_timeout"
        save_config
    else
        echo -e "${RED}Valeur invalide (minimum 30s)${NC}"
    fi
}

configure_alert_cooldown() {
    echo -e "${YELLOW}Entrez le cooldown entre alertes (secondes):${NC}"
    echo -e "${BLUE}Valeur actuelle: $(get_config ALERT_COOLDOWN)${NC}"
    read -r new_cooldown
    
    if [[ "$new_cooldown" =~ ^[0-9]+$ ]] && (( new_cooldown >= 60 )); then
        set_config "ALERT_COOLDOWN" "$new_cooldown"
        save_config
    else
        echo -e "${RED}Valeur invalide (minimum 60s)${NC}"
    fi
}

configure_interface() {
    echo -e "${YELLOW}Entrez l'interface réseau (vide pour auto-détection):${NC}"
    echo -e "${BLUE}Interface actuelle: $(get_config INTERFACE)${NC}"
    echo -e "${CYAN}Interfaces disponibles:${NC}"
    ip link show | grep -E '^[0-9]+:' | cut -d: -f2 | tr -d ' '
    read -r new_interface
    
    if [[ -n "$new_interface" ]]; then
        set_config "INTERFACE" "$new_interface"
    else
        set_config "INTERFACE" "$(detect_network_interface)"
    fi
    save_config
}

configure_log_level() {
    echo -e "${YELLOW}Choisissez le niveau de log:${NC}"
    echo "1) DEBUG"
    echo "2) INFO"
    echo "3) WARN"
    echo "4) ERROR"
    echo -e "${BLUE}Niveau actuel: $(get_config LOG_LEVEL)${NC}"
    read -r choice
    
    case $choice in
        1) set_config "LOG_LEVEL" "DEBUG" ;;
        2) set_config "LOG_LEVEL" "INFO" ;;
        3) set_config "LOG_LEVEL" "WARN" ;;
        4) set_config "LOG_LEVEL" "ERROR" ;;
        *) echo -e "${RED}Choix invalide${NC}"; return ;;
    esac
    save_config
}

update_meshwatch() {
    clear
    echo -e "${PURPLE}=== Mise à jour MeshWatch Star Déception ===${NC}"
    echo ""
    
    # Vérifier si on est dans un repo Git
    if [[ ! -d "$SCRIPT_DIR/.git" ]]; then
        echo -e "${RED}Erreur: MeshWatch n'est pas dans un dépôt Git${NC}"
        echo -e "${YELLOW}Clonez le projet avec: git clone <repository-url>${NC}"
        return 1
    fi
    
    # Vérifier la connectivité
    echo -e "${BLUE}Vérification de la connectivité...${NC}"
    if ! git -C "$SCRIPT_DIR" fetch --dry-run 2>/dev/null; then
        echo -e "${RED}Erreur: Impossible de contacter le dépôt distant${NC}"
        return 1
    fi
    
    # Vérifier s'il y a des mises à jour
    local current_commit=$(git -C "$SCRIPT_DIR" rev-parse HEAD)
    local remote_commit=$(git -C "$SCRIPT_DIR" rev-parse origin/main 2>/dev/null || git -C "$SCRIPT_DIR" rev-parse origin/master 2>/dev/null)
    
    if [[ "$current_commit" == "$remote_commit" ]]; then
        echo -e "${GREEN}✅ MeshWatch est déjà à jour !${NC}"
        echo -e "${CYAN}Version actuelle: $MESHWATCH_VERSION${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}📦 Mise à jour disponible !${NC}"
    echo -e "${BLUE}Commit actuel: ${current_commit:0:8}${NC}"
    echo -e "${BLUE}Nouveau commit: ${remote_commit:0:8}${NC}"
    echo ""
    
    # Demander confirmation
    echo -n "Voulez-vous mettre à jour ? (o/N): "
    read -r confirm
    if [[ ! "$confirm" =~ ^[oO]$ ]]; then
        echo -e "${YELLOW}Mise à jour annulée${NC}"
        return 0
    fi
    
    # Arrêter le monitoring si actif
    if is_monitoring_active; then
        echo -e "${BLUE}Arrêt de la surveillance mesh...${NC}"
        stop_monitoring_safe
    fi
    
    # Sauvegarder la configuration
    echo -e "${BLUE}Sauvegarde de la configuration...${NC}"
    local backup_file="/tmp/meshwatch_config_backup_$(date +%s).conf"
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "$backup_file"
        echo -e "${GREEN}Configuration sauvegardée: $backup_file${NC}"
    fi
    
    # Effectuer la mise à jour
    echo -e "${BLUE}Téléchargement des mises à jour...${NC}"
    if git -C "$SCRIPT_DIR" pull; then
        echo -e "${GREEN}✅ Mise à jour réussie !${NC}"
        
        # Restaurer la configuration si elle existe
        if [[ -f "$backup_file" ]]; then
            cp "$backup_file" "$CONFIG_FILE"
            echo -e "${GREEN}Configuration restaurée${NC}"
        fi
        
        # Rendre le script exécutable
        chmod +x "$SCRIPT_DIR/meshwatch.sh"
        chmod +x "$SCRIPT_DIR/src/"*.sh
        
        echo ""
        echo -e "${CYAN}🚀 MeshWatch Star Déception mis à jour avec succès !${NC}"
        echo -e "${YELLOW}Redémarrez le script pour appliquer les changements${NC}"
        echo ""
        echo -n "Redémarrer maintenant ? (o/N): "
        read -r restart
        if [[ "$restart" =~ ^[oO]$ ]]; then
            echo -e "${GREEN}Redémarrage...${NC}"
            sleep 2
            exec "$SCRIPT_DIR/meshwatch.sh"
        fi
    else
        echo -e "${RED}❌ Erreur lors de la mise à jour${NC}"
        if [[ -f "$backup_file" ]]; then
            echo -e "${BLUE}Configuration de sauvegarde disponible: $backup_file${NC}"
        fi
        return 1
    fi
}

show_version_info() {
    clear
    echo -e "${PURPLE}=== Informations Version ===${NC}"
    echo ""
    echo -e "${WHITE}MeshWatch Star Déception${NC}"
    echo -e "${CYAN}Version: $MESHWATCH_VERSION${NC}"
    echo -e "${CYAN}Build: $BUILD_DATE${NC}"
    echo ""
    
    # Informations Git si disponible
    if [[ -d "$SCRIPT_DIR/.git" ]]; then
        local commit=$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || echo "inconnu")
        local branch=$(git -C "$SCRIPT_DIR" branch --show-current 2>/dev/null || echo "inconnu")
        local last_commit_date=$(git -C "$SCRIPT_DIR" log -1 --format=%cd --date=short 2>/dev/null || echo "inconnu")
        
        echo -e "${WHITE}Informations Git:${NC}"
        echo -e "${BLUE}  Branche: $branch${NC}"
        echo -e "${BLUE}  Commit: $commit${NC}"
        echo -e "${BLUE}  Dernière modification: $last_commit_date${NC}"
        echo ""
    fi
    
    echo -e "${WHITE}Architecture:${NC}"
    echo -e "${BLUE}  Système: $(uname -s) $(uname -m)${NC}"
    echo -e "${BLUE}  Bash: $BASH_VERSION${NC}"
    echo ""
    
    echo -e "${WHITE}Répertoires:${NC}"
    echo -e "${BLUE}  Script: $SCRIPT_DIR${NC}"
    echo -e "${BLUE}  Config: $CONFIG_DIR${NC}"
    echo -e "${BLUE}  Logs: $LOGS_DIR${NC}"
    echo ""
    
    echo -e "${WHITE}Star Déception - Architecture Mesh Dynamique${NC}"
    echo -e "${CYAN}Surveillance réseau pour serveurs maillés${NC}"
}

start_ui() {
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1)
                start_monitoring
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
                update_meshwatch
                read -p "$(get_message "press_enter")" -r
                ;;
            11)
                show_version_info
                read -p "$(get_message "press_enter")" -r
                ;;
            12)
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