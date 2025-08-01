#!/bin/bash

# =============================================================================
# Module de gestion de la configuration
# =============================================================================

readonly CONFIG_FILE="$CONFIG_DIR/meshwatch.conf"
readonly DEFAULT_CONFIG_FILE="$CONFIG_DIR/default.conf"

# Variables de configuration par défaut
declare -A DEFAULT_CONFIG=(
    ["PORTS"]="7777,7778,7779"
    ["ORCHESTRATOR_HOST"]="orchestrator.star-deception.com"
    ["DISCORD_WEBHOOK"]=""
    ["MONITORING_ENABLED"]="false"
    ["LOGGING_ENABLED"]="true"
    ["LANG"]="fr"
    ["ALERT_TIMEOUT"]="120"
    ["MAX_CONN"]="150"
    ["MAX_BANDWIDTH_MBPS"]="500"
    ["INTERFACE"]=""
    ["ALERT_COOLDOWN"]="300"
    ["LOG_ROTATION_SIZE"]="10M"
    ["LOG_LEVEL"]="INFO"
)

# Variables globales de configuration
declare -A CONFIG

# =============================================================================
# FONCTIONS DE CONFIGURATION
# =============================================================================

init_config() {
    # Créer la configuration par défaut si elle n'existe pas
    if [[ ! -f "$DEFAULT_CONFIG_FILE" ]]; then
        create_default_config
    fi
    
    # Créer la configuration utilisateur si elle n'existe pas
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cp "$DEFAULT_CONFIG_FILE" "$CONFIG_FILE"
    fi
}

create_default_config() {
    cat > "$DEFAULT_CONFIG_FILE" << 'EOF'
# =============================================================================
# Configuration MeshWatch pour Star Déception
# =============================================================================

# Ports mesh Star Déception (liste séparée par virgules ou plages)
PORTS="7777,7778,7779"

# Orchestrateur central Star Déception
ORCHESTRATOR_HOST="orchestrator.star-deception.com"

# Webhook Discord pour alertes mesh (#mesh-monitoring)
DISCORD_WEBHOOK=""

# État du monitoring (true/false)
MONITORING_ENABLED="false"

# Journalisation activée (true/false)
LOGGING_ENABLED="true"

# Langue de l'interface (fr/en)
LANG="fr"

# Timeout entre les vérifications (secondes)
ALERT_TIMEOUT="120"

# Nombre maximum de connexions mesh simultanées
MAX_CONN="150"

# Débit mesh maximum autorisé (Mbps)
MAX_BANDWIDTH_MBPS="500"

# Interface réseau mesh (auto-détection si vide)
INTERFACE=""

# Cooldown entre les alertes du même type (secondes)
ALERT_COOLDOWN="300"

# Taille maximum des logs avant rotation
LOG_ROTATION_SIZE="10M"

# Niveau de log (DEBUG/INFO/WARN/ERROR)
LOG_LEVEL="INFO"
EOF
}

load_config() {
    # Charger la configuration par défaut
    while IFS='=' read -r key value; do
        # Ignorer les commentaires et lignes vides
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        
        # Nettoyer les guillemets
        value=$(echo "$value" | sed 's/^"//;s/"$//')
        CONFIG["$key"]="$value"
    done < "$DEFAULT_CONFIG_FILE"
    
    # Surcharger avec la configuration utilisateur
    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS='=' read -r key value; do
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            
            value=$(echo "$value" | sed 's/^"//;s/"$//')
            CONFIG["$key"]="$value"
        done < "$CONFIG_FILE"
    fi
    
    # Auto-détecter l'interface si nécessaire
    if [[ -z "${CONFIG[INTERFACE]}" ]]; then
        CONFIG["INTERFACE"]=$(detect_network_interface)
    fi
    
    # Exporter les variables pour les autres modules
    export_config_vars
}

save_config() {
    cat > "$CONFIG_FILE" << EOF
# =============================================================================
# Configuration MeshWatch Star Déception - Générée automatiquement
# =============================================================================

PORTS="${CONFIG[PORTS]}"
ORCHESTRATOR_HOST="${CONFIG[ORCHESTRATOR_HOST]}"
DISCORD_WEBHOOK="${CONFIG[DISCORD_WEBHOOK]}"
MONITORING_ENABLED="${CONFIG[MONITORING_ENABLED]}"
LOGGING_ENABLED="${CONFIG[LOGGING_ENABLED]}"
LANG="${CONFIG[LANG]}"
ALERT_TIMEOUT="${CONFIG[ALERT_TIMEOUT]}"
MAX_CONN="${CONFIG[MAX_CONN]}"
MAX_BANDWIDTH_MBPS="${CONFIG[MAX_BANDWIDTH_MBPS]}"
INTERFACE="${CONFIG[INTERFACE]}"
ALERT_COOLDOWN="${CONFIG[ALERT_COOLDOWN]}"
LOG_ROTATION_SIZE="${CONFIG[LOG_ROTATION_SIZE]}"
LOG_LEVEL="${CONFIG[LOG_LEVEL]}"
EOF
    log_message "INFO" "Configuration sauvegardée"
}

export_config_vars() {
    for key in "${!CONFIG[@]}"; do
        export "$key"="${CONFIG[$key]}"
    done
}

get_config() {
    local key="$1"
    echo "${CONFIG[$key]:-}"
}

set_config() {
    local key="$1"
    local value="$2"
    CONFIG["$key"]="$value"
}

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

validate_webhook() {
    local webhook="$1"
    [[ "$webhook" =~ ^https://discord(app)?\.com/api/webhooks/[0-9]+/[a-zA-Z0-9_-]+$ ]]
}