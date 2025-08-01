#!/bin/bash

# =============================================================================
# Module de surveillance réseau
# =============================================================================

readonly STATS_CACHE="/tmp/meshwatch_stats_cache"
readonly INTERFACE_CACHE="/tmp/meshwatch_interface_cache"

# =============================================================================
# FONCTIONS RÉSEAU
# =============================================================================

detect_network_interface() {
    # Utiliser le cache si récent (< 60 secondes)
    if [[ -f "$INTERFACE_CACHE" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$INTERFACE_CACHE" 2>/dev/null || echo 0)))
        if (( cache_age < 60 )); then
            cat "$INTERFACE_CACHE"
            return 0
        fi
    fi
    
    # Chercher l'interface avec une route par défaut
    local interface=$(ip route show default 2>/dev/null | head -1 | awk '{print $5}')
    
    # Si pas trouvé, chercher la première interface active (pas lo)
    if [[ -z "$interface" ]]; then
        interface=$(ip link show up 2>/dev/null | grep -E '^[0-9]+:' | grep -v 'lo:' | head -1 | cut -d: -f2 | tr -d ' ')
    fi
    
    # Fallback sur eth0
    interface="${interface:-eth0}"
    
    # Mettre en cache
    echo "$interface" > "$INTERFACE_CACHE"
    echo "$interface"
}

get_network_stats() {
    local interface="${1:-$(get_config INTERFACE)}"
    
    # Utiliser le cache si récent (< 2 secondes)
    if [[ -f "$STATS_CACHE" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$STATS_CACHE" 2>/dev/null || echo 0)))
        if (( cache_age < 2 )); then
            cat "$STATS_CACHE"
            return 0
        fi
    fi
    
    # Construire la liste des ports pour ss
    local port_list=""
    local ports=$(get_config PORTS)
    
    IFS=',' read -ra PORT_ARRAY <<< "$ports"
    for port in "${PORT_ARRAY[@]}"; do
        if [[ "$port" =~ ^[0-9]+-[0-9]+$ ]]; then
            # Plage de ports - développer en ports individuels (limité à 100 ports)
            local start_port=$(echo "$port" | cut -d- -f1)
            local end_port=$(echo "$port" | cut -d- -f2)
            local count=0
            for ((p=start_port; p<=end_port && count<100; p++)); do
                if [[ -n "$port_list" ]]; then
                    port_list="$port_list,$p"
                else
                    port_list="$p"
                fi
                ((count++))
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
        connections=$(ss -tuln 2>/dev/null | grep -E ":($port_list)" | wc -l || echo 0)
    fi
    
    # Obtenir les statistiques de l'interface
    local net_stats
    if net_stats=$(grep "^[[:space:]]*$interface:" /proc/net/dev 2>/dev/null); then
        local rx_bytes=$(echo "$net_stats" | awk '{print $2}')
        local tx_bytes=$(echo "$net_stats" | awk '{print $10}')
    else
        local rx_bytes=0
        local tx_bytes=0
    fi
    
    local timestamp=$(date +%s)
    local result="$connections:$rx_bytes:$tx_bytes:$timestamp"
    
    # Mettre en cache
    echo "$result" > "$STATS_CACHE"
    echo "$result"
}

calculate_bandwidth() {
    local current_stats="$1"
    local previous_stats="$2"
    
    if [[ -z "$previous_stats" ]]; then
        echo "0"
        return
    fi
    
    local current_tx=$(echo "$current_stats" | cut -d: -f3)
    local current_time=$(echo "$current_stats" | cut -d: -f4)
    local prev_tx=$(echo "$previous_stats" | cut -d: -f3)
    local prev_time=$(echo "$previous_stats" | cut -d: -f4)
    
    local diff_bytes=$((current_tx - prev_tx))
    local diff_time=$((current_time - prev_time))
    
    if (( diff_time > 0 )); then
        # Convertir en Mbps (bytes/sec * 8 / 1024 / 1024)
        local bandwidth_mbps=$((diff_bytes * 8 / diff_time / 1024 / 1024))
        echo "$bandwidth_mbps"
    else
        echo "0"
    fi
}

check_orchestrator() {
    local host=$(get_config ORCHESTRATOR_HOST)
    
    if [[ -z "$host" || "$host" == "orchestrator.example.com" ]]; then
        echo "disabled"
        return 0
    fi
    
    if timeout 5 ping -c 1 "$host" >/dev/null 2>&1; then
        echo "ok"
    else
        echo "timeout"
    fi
}

get_active_connections() {
    local ports=$(get_config PORTS)
    local port_list=""
    
    # Construire la liste des ports
    IFS=',' read -ra PORT_ARRAY <<< "$ports"
    for port in "${PORT_ARRAY[@]}"; do
        if [[ "$port" =~ ^[0-9]+-[0-9]+$ ]]; then
            local start_port=$(echo "$port" | cut -d- -f1)
            local end_port=$(echo "$port" | cut -d- -f2)
            for ((p=start_port; p<=end_port; p++)); do
                if [[ -n "$port_list" ]]; then
                    port_list="$port_list|$p"
                else
                    port_list="$p"
                fi
            done
        else
            if [[ -n "$port_list" ]]; then
                port_list="$port_list|$port"
            else
                port_list="$port"
            fi
        fi
    done
    
    if [[ -n "$port_list" ]]; then
        ss -tuln 2>/dev/null | grep -E ":($port_list)" | head -20
    fi
}

get_network_processes() {
    local ports=$(get_config PORTS)
    netstat -tulpn 2>/dev/null | grep -E ":($ports)" | head -10
}