#!/bin/bash

# =============================================================================
# Module de gestion des alertes
# =============================================================================

readonly COOLDOWN_DIR="/tmp/meshwatch_cooldowns"

# Créer le répertoire des cooldowns
mkdir -p "$COOLDOWN_DIR"

# =============================================================================
# FONCTIONS D'ALERTES
# =============================================================================

check_alert_cooldown() {
    local alert_type="$1"
    local cooldown_file="$COOLDOWN_DIR/${alert_type}"
    local current_time=$(date +%s)
    local cooldown_duration=$(get_config ALERT_COOLDOWN)
    
    if [[ -f "$cooldown_file" ]]; then
        local last_alert=$(cat "$cooldown_file" 2>/dev/null || echo 0)
        local time_diff=$((current_time - last_alert))
        
        if (( time_diff < cooldown_duration )); then
            return 1  # Encore en cooldown
        fi
    fi
    
    echo "$current_time" > "$cooldown_file"
    return 0  # Peut envoyer l'alerte
}

send_discord_alert() {
    local title="$1"
    local description="$2"
    local color="$3"
    local webhook=$(get_config DISCORD_WEBHOOK)
    
    if [[ -z "$webhook" ]]; then
        log_message "DEBUG" "Webhook Discord non configuré, alerte ignorée"
        return 0
    fi
    
    local hostname=$(hostname)
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)
    
    local payload=$(cat << EOF
{
    "embeds": [{
        "title": "$title",
        "description": "$description",
        "color": $color,
        "timestamp": "$timestamp",
        "footer": {
            "text": "MeshWatch Alert System - $hostname"
        },
        "fields": [
            {
                "name": "Serveur",
                "value": "$hostname",
                "inline": true
            },
            {
                "name": "Interface",
                "value": "$(get_config INTERFACE)",
                "inline": true
            }
        ]
    }]
}
EOF
)
    
    if curl -H "Content-Type: application/json" \
            -X POST \
            -d "$payload" \
            "$webhook" \
            --silent --output /dev/null --max-time 10; then
        log_message "DEBUG" "Alerte Discord envoyée: $title"
    else
        log_message "ERROR" "Échec envoi alerte Discord: $title"
    fi
}

detect_anomalies() {
    local connections="$1"
    local bandwidth_mbps="$2"
    local orchestrator_status="$3"
    
    local max_conn=$(get_config MAX_CONN)
    local max_bandwidth=$(get_config MAX_BANDWIDTH_MBPS)
    
    # Vérifier le nombre de connexions
    if (( connections > max_conn )); then
        if check_alert_cooldown "high_connections"; then
            log_message "WARN" "$(get_message "alert_high_connections"): $connections"
            send_discord_alert "⚠️ $(get_message "alert_high_connections")" \
                              "$(get_message "connections"): $connections/$max_conn" \
                              16776960  # Orange
        fi
    fi
    
    # Vérifier le débit
    if (( bandwidth_mbps > max_bandwidth )); then
        if check_alert_cooldown "high_bandwidth"; then
            log_message "WARN" "$(get_message "alert_high_bandwidth"): ${bandwidth_mbps}Mbps"
            send_discord_alert "⚠️ $(get_message "alert_high_bandwidth")" \
                              "$(get_message "bandwidth"): ${bandwidth_mbps}Mbps/${max_bandwidth}Mbps" \
                              16711680  # Rouge
        fi
    fi
    
    # Vérifier l'orchestrateur
    if [[ "$orchestrator_status" == "timeout" ]]; then
        if check_alert_cooldown "orchestrator_timeout"; then
            log_message "ERROR" "$(get_message "alert_orchestrator_timeout")"
            send_discord_alert "🔴 $(get_message "alert_orchestrator_timeout")" \
                              "Host: $(get_config ORCHESTRATOR_HOST)" \
                              16711680  # Rouge
        fi
    fi
    
    # Vérifier l'absence de flux sortant
    if (( connections == 0 && bandwidth_mbps == 0 )); then
        if check_alert_cooldown "no_outbound"; then
            log_message "WARN" "$(get_message "alert_no_outbound")"
            send_discord_alert "⚠️ $(get_message "alert_no_outbound")" \
                              "Aucune activité réseau détectée" \
                              16776960  # Orange
        fi
    fi
}

test_discord_webhook() {
    local webhook="$1"
    
    if [[ -z "$webhook" ]]; then
        return 1
    fi
    
    local test_payload='{"content":"🧪 Test MeshWatch - Webhook configuré avec succès!"}'
    
    if curl -H "Content-Type: application/json" \
            -X POST \
            -d "$test_payload" \
            "$webhook" \
            --silent --output /dev/null --max-time 10; then
        return 0
    else
        return 1
    fi
}