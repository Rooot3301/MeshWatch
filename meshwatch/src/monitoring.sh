#!/bin/bash

# =============================================================================
# Module de monitoring principal
# =============================================================================

readonly PID_FILE="/tmp/meshwatch.pid"

# =============================================================================
# FONCTIONS DE MONITORING
# =============================================================================

is_monitoring_active() {
    [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null
}

start_monitoring() {
    if is_monitoring_active; then
        echo -e "${YELLOW}$(get_message "monitoring_already_running")${NC}"
        return 1
    fi
    
    log_message "INFO" "$(get_message "monitoring_started")"
    echo -e "${GREEN}$(get_message "monitoring_started")${NC}"
    
    # Démarrer le daemon en arrière-plan
    (
        echo $$ > "$PID_FILE"
        monitoring_loop
    ) &
    
    set_config "MONITORING_ENABLED" "true"
    save_config
}

stop_monitoring() {
    if ! is_monitoring_active; then
        echo -e "${YELLOW}$(get_message "monitoring_not_running")${NC}"
        return 1
    fi
    
    local pid=$(cat "$PID_FILE" 2>/dev/null)
    if [[ -n "$pid" ]]; then
        kill "$pid" 2>/dev/null
        # Attendre que le processus se termine
        local count=0
        while kill -0 "$pid" 2>/dev/null && (( count < 10 )); do
            sleep 1
            ((count++))
        done
        
        # Forcer l'arrêt si nécessaire
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null
        fi
    fi
    
    rm -f "$PID_FILE"
    
    set_config "MONITORING_ENABLED" "false"
    save_config
    
    echo -e "${GREEN}$(get_message "monitoring_stopped")${NC}"
}

stop_monitoring_safe() {
    if is_monitoring_active; then
        local pid=$(cat "$PID_FILE" 2>/dev/null)
        if [[ -n "$pid" ]]; then
            kill "$pid" 2>/dev/null
            sleep 1
            if kill -0 "$pid" 2>/dev/null; then
                kill -9 "$pid" 2>/dev/null
            fi
        fi
        rm -f "$PID_FILE"
        set_config "MONITORING_ENABLED" "false"
    fi
}

monitoring_loop() {
    local prev_stats=""
    local alert_timeout=$(get_config ALERT_TIMEOUT)
    
    log_message "INFO" "Démarrage de la boucle de monitoring (timeout: ${alert_timeout}s)"
    
    while true; do
        # Vérifier si le monitoring doit continuer
        if [[ ! -f "$PID_FILE" ]]; then
            log_message "INFO" "Fichier PID supprimé, arrêt du monitoring"
            break
        fi
        
        # Obtenir les statistiques réseau
        local current_stats=$(get_network_stats)
        local connections=$(echo "$current_stats" | cut -d: -f1)
        
        # Calculer le débit
        local bandwidth_mbps=0
        if [[ -n "$prev_stats" ]]; then
            bandwidth_mbps=$(calculate_bandwidth "$current_stats" "$prev_stats")
        fi
        
        # Vérifier l'orchestrateur
        local orchestrator_status=$(check_orchestrator)
        
        # Log des statistiques (niveau DEBUG)
        log_message "DEBUG" "Stats: connexions=$connections, débit=${bandwidth_mbps}Mbps, orchestrateur=$orchestrator_status"
        
        # Détecter les anomalies
        detect_anomalies "$connections" "$bandwidth_mbps" "$orchestrator_status"
        
        prev_stats="$current_stats"
        sleep "$alert_timeout"
    done
    
    log_message "INFO" "Fin de la boucle de monitoring"
}

get_monitoring_status() {
    if is_monitoring_active; then
        local pid=$(cat "$PID_FILE" 2>/dev/null)
        local uptime=$(ps -o etime= -p "$pid" 2>/dev/null | tr -d ' ')
        echo "running:$pid:$uptime"
    else
        echo "stopped"
    fi
}