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
        printf "\033[1;33m%s\033[0m\n" "$(get_message "monitoring_already_running")"
        return 1
    fi
    
    # Vérifier la configuration avant de démarrer
    local interface=$(get_config INTERFACE)
    if [[ -z "$interface" ]]; then
        interface=$(detect_network_interface)
        set_config "INTERFACE" "$interface"
        save_config
    fi
    
    # Vérifier que l'interface existe
    if ! ip link show "$interface" >/dev/null 2>&1; then
        printf "\033[0;31mErreur: Interface réseau '%s' non trouvée\033[0m\n" "$interface"
        printf "\033[1;33mInterfaces disponibles:\033[0m\n"
        ip link show | grep -E '^[0-9]+:' | cut -d: -f2 | tr -d ' '
        return 1
    fi
    
    # Vérifier les ports configurés
    local ports=$(get_config PORTS)
    if ! validate_ports "$ports"; then
        printf "\033[0;31mErreur: Configuration des ports invalide: %s\033[0m\n" "$ports"
        return 1
    fi
    
    # Démarrer le daemon en arrière-plan
    (
        echo $$ > "$PID_FILE"
        # Attendre un peu pour s'assurer que le PID est écrit
        sleep 1
        monitoring_loop
    ) &
    
    # Attendre que le processus démarre
    sleep 2
    
    # Vérifier que le monitoring a bien démarré
    if is_monitoring_active; then
        log_message "INFO" "$(get_message "monitoring_started")"
        printf "\033[0;32m%s\033[0m\n" "$(get_message "monitoring_started")"
        printf "\033[1;36mInterface: %s | Ports: %s\033[0m\n" "$interface" "$(get_config PORTS)"
    else
        printf "\033[0;31mErreur: Impossible de démarrer la surveillance\033[0m\n"
        return 1
    fi
    
    set_config "MONITORING_ENABLED" "true"
    save_config
}

stop_monitoring() {
    if ! is_monitoring_active; then
        printf "\033[1;33m%s\033[0m\n" "$(get_message "monitoring_not_running")"
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
    
    printf "\033[0;32m%s\033[0m\n" "$(get_message "monitoring_stopped")"
}

stop_monitoring_safe() {
    # Version silencieuse pour cleanup
    if is_monitoring_active; then
        local pid=$(cat "$PID_FILE" 2>/dev/null)
        if [[ -n "$pid" ]]; then
            kill -TERM "$pid" 2>/dev/null || true
            local count=0
            while kill -0 "$pid" 2>/dev/null && (( count < 5 )); do
                sleep 1
                ((count++))
            done
            if kill -0 "$pid" 2>/dev/null; then
                kill -KILL "$pid" 2>/dev/null || true
            fi
        fi
        rm -f "$PID_FILE"
        # Ne pas sauvegarder la config dans cleanup pour éviter les boucles
    fi
}

monitoring_loop() {
    local prev_stats=""
    local alert_timeout=$(get_config ALERT_TIMEOUT)
    local interface=$(get_config INTERFACE)
    
    log_message "INFO" "Démarrage surveillance mesh - Interface: $interface, Timeout: ${alert_timeout}s"
    
    while true; do
        # Vérifier si le monitoring doit continuer
        if [[ ! -f "$PID_FILE" ]]; then
            log_message "INFO" "Fichier PID supprimé, arrêt du monitoring"
            break
        fi
        
        # Obtenir les statistiques réseau avec gestion d'erreur
        local current_stats
        if ! current_stats=$(get_network_stats); then
            log_message "ERROR" "Impossible d'obtenir les statistiques réseau"
            sleep "$alert_timeout"
            continue
        fi
        
        local connections=$(echo "$current_stats" | cut -d: -f1)
        
        # Calculer le débit
        local bandwidth_mbps=0
        if [[ -n "$prev_stats" ]]; then
            bandwidth_mbps=$(calculate_bandwidth "$current_stats" "$prev_stats")
        fi
        
        # Vérifier l'orchestrateur
        local orchestrator_status=$(check_orchestrator)
        
        # Log des statistiques (niveau DEBUG)
        log_message "DEBUG" "Stats mesh: connexions=$connections, débit=${bandwidth_mbps}Mbps, orchestrateur=$orchestrator_status"
        
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