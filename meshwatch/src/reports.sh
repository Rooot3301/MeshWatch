#!/bin/bash

# =============================================================================
# Module de génération de rapports
# =============================================================================

readonly TEMP_DATA_FILE="/tmp/meshwatch_temp_data.log"

# =============================================================================
# FONCTIONS DE RAPPORT
# =============================================================================

start_temporary_monitoring() {
    local duration="$1"
    local format="${2:-txt}"
    
    if is_monitoring_active; then
        printf "\033[1;33mArrêt de la surveillance existante...\033[0m\n"
        stop_monitoring_safe
        sleep 2
    fi
    
    printf "\033[0;36m=== Surveillance temporaire MeshWatch ===\033[0m\n"
    printf "\033[1;37mDurée: %s secondes | Format: %s\033[0m\n" "$duration" "$format"
    printf "\033[1;33mDémarrage de la collecte de données...\033[0m\n"
    
    # Initialiser le fichier de données temporaires
    echo "# MeshWatch Temporary Data Collection" > "$TEMP_DATA_FILE"
    echo "# Start Time: $(date)" >> "$TEMP_DATA_FILE"
    echo "# Duration: ${duration}s" >> "$TEMP_DATA_FILE"
    echo "# Interface: $(get_config INTERFACE)" >> "$TEMP_DATA_FILE"
    echo "# Ports: $(get_config PORTS)" >> "$TEMP_DATA_FILE"
    echo "# Orchestrator: $(get_config ORCHESTRATOR_HOST)" >> "$TEMP_DATA_FILE"
    echo "" >> "$TEMP_DATA_FILE"
    
    # Démarrer la surveillance temporaire
    (
        echo $$ > "/tmp/meshwatch.pid"
        temporary_monitoring_loop "$duration"
    ) &
    
    local monitoring_pid=$!
    sleep 2
    
    # Barre de progression
    show_progress_bar "$duration" "$monitoring_pid"
    
    # Attendre la fin de la surveillance
    wait "$monitoring_pid" 2>/dev/null
    
    # Générer le rapport
    printf "\n\033[0;32mCollecte terminée ! Génération du rapport...\033[0m\n"
    generate_report "$format"
    
    # Nettoyer
    rm -f "/tmp/meshwatch.pid" "$TEMP_DATA_FILE"
}

temporary_monitoring_loop() {
    local duration="$1"
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    local prev_stats=""
    local sample_interval=5  # Échantillonnage toutes les 5 secondes
    
    log_message "INFO" "Démarrage surveillance temporaire pour ${duration}s"
    
    while (( $(date +%s) < end_time )); do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        # Obtenir les statistiques
        local current_stats=$(get_network_stats)
        local connections=$(echo "$current_stats" | cut -d: -f1)
        local rx_bytes=$(echo "$current_stats" | cut -d: -f2)
        local tx_bytes=$(echo "$current_stats" | cut -d: -f3)
        
        # Calculer le débit
        local bandwidth_mbps=0
        if [[ -n "$prev_stats" ]]; then
            bandwidth_mbps=$(calculate_bandwidth "$current_stats" "$prev_stats")
        fi
        
        # Vérifier l'orchestrateur
        local orchestrator_status=$(check_orchestrator)
        
        # Obtenir des informations supplémentaires
        local active_connections_count=$(get_active_connections | wc -l)
        local network_processes_count=$(get_network_processes | wc -l)
        
        # Enregistrer les données
        echo "${elapsed},${connections},${bandwidth_mbps},${orchestrator_status},${active_connections_count},${network_processes_count},${rx_bytes},${tx_bytes}" >> "$TEMP_DATA_FILE"
        
        prev_stats="$current_stats"
        sleep "$sample_interval"
    done
    
    log_message "INFO" "Fin surveillance temporaire"
}

show_progress_bar() {
    local duration="$1"
    local monitoring_pid="$2"
    local start_time=$(date +%s)
    
    while kill -0 "$monitoring_pid" 2>/dev/null; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        local progress=$((elapsed * 100 / duration))
        
        # Limiter le progrès à 100%
        if (( progress > 100 )); then
            progress=100
        fi
        
        # Créer la barre de progression
        local bar_length=50
        local filled_length=$((progress * bar_length / 100))
        local bar=""
        
        for ((i=0; i<filled_length; i++)); do
            bar+="█"
        done
        for ((i=filled_length; i<bar_length; i++)); do
            bar+="░"
        done
        
        printf "\r\033[0;36m[%s] %d%% (%ds/%ds)\033[0m" "$bar" "$progress" "$elapsed" "$duration"
        
        sleep 1
    done
    
    printf "\r\033[0;36m[%s] 100%% (%ds/%ds)\033[0m" "$(printf '█%.0s' {1..50})" "$duration" "$duration"
}

generate_report() {
    local format="$1"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local hostname=$(hostname)
    
    case "$format" in
        "html")
            generate_html_report "$timestamp" "$hostname"
            ;;
        "txt"|*)
            generate_txt_report "$timestamp" "$hostname"
            ;;
    esac
}

generate_txt_report() {
    local timestamp="$1"
    local hostname="$2"
    local report_file="$REPORTS_DIR/meshwatch_report_${timestamp}.txt"
    
    # Analyser les données
    local data_analysis=$(analyze_collected_data)
    
    cat > "$report_file" << EOF
================================================================================
                    RAPPORT MESHWATCH STAR DÉCEPTION
================================================================================

Informations Générales:
  Nœud Mesh: $hostname
  Date/Heure: $(date)
  Interface: $(get_config INTERFACE)
  Ports surveillés: $(get_config PORTS)
  Orchestrateur: $(get_config ORCHESTRATOR_HOST)

$(echo "$data_analysis")

================================================================================
Données Brutes:
================================================================================

Timestamp,Connexions,Débit(Mbps),Orchestrateur,Conn.Actives,Processus,RX(bytes),TX(bytes)
$(grep -v '^#' "$TEMP_DATA_FILE" | grep -v '^$')

================================================================================
Fin du rapport - MeshWatch v$MESHWATCH_VERSION
================================================================================
EOF

    printf "\033[0;32m✅ Rapport TXT généré: %s\033[0m\n" "$report_file"
    
    # Afficher un résumé
    echo ""
    echo -e "\033[1;37m=== Résumé du Rapport ===\033[0m"
    echo "$data_analysis" | head -20
}

generate_html_report() {
    local timestamp="$1"
    local hostname="$2"
    local report_file="$REPORTS_DIR/meshwatch_report_${timestamp}.html"
    
    # Analyser les données
    local data_analysis=$(analyze_collected_data)
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport MeshWatch Star Déception - $timestamp</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #2c3e50, #3498db);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .header .subtitle {
            margin-top: 10px;
            opacity: 0.9;
            font-size: 1.2em;
        }
        .content {
            padding: 30px;
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .info-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            border-left: 4px solid #3498db;
        }
        .info-card h3 {
            margin: 0 0 10px 0;
            color: #2c3e50;
        }
        .analysis {
            background: #e8f5e8;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
            border-left: 4px solid #27ae60;
        }
        .data-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
            font-size: 0.9em;
        }
        .data-table th,
        .data-table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        .data-table th {
            background: #3498db;
            color: white;
            font-weight: bold;
        }
        .data-table tr:nth-child(even) {
            background: #f2f2f2;
        }
        .data-table tr:hover {
            background: #e3f2fd;
        }
        .footer {
            background: #2c3e50;
            color: white;
            padding: 20px;
            text-align: center;
        }
        .status-ok { color: #27ae60; font-weight: bold; }
        .status-warning { color: #f39c12; font-weight: bold; }
        .status-error { color: #e74c3c; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🌌 MeshWatch Star Déception</h1>
            <div class="subtitle">Rapport de Surveillance Mesh - $timestamp</div>
        </div>
        
        <div class="content">
            <div class="info-grid">
                <div class="info-card">
                    <h3>🖥️ Nœud Mesh</h3>
                    <p>$hostname</p>
                </div>
                <div class="info-card">
                    <h3>🌐 Interface</h3>
                    <p>$(get_config INTERFACE)</p>
                </div>
                <div class="info-card">
                    <h3>🔌 Ports Surveillés</h3>
                    <p>$(get_config PORTS)</p>
                </div>
                <div class="info-card">
                    <h3>🎯 Orchestrateur</h3>
                    <p>$(get_config ORCHESTRATOR_HOST)</p>
                </div>
            </div>
            
            <div class="analysis">
                <h2>📊 Analyse des Données</h2>
                <pre>$(echo "$data_analysis" | sed 's/</\&lt;/g; s/>/\&gt;/g')</pre>
            </div>
            
            <h2>📈 Données Collectées</h2>
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Temps (s)</th>
                        <th>Connexions</th>
                        <th>Débit (Mbps)</th>
                        <th>Orchestrateur</th>
                        <th>Conn. Actives</th>
                        <th>Processus</th>
                        <th>RX (bytes)</th>
                        <th>TX (bytes)</th>
                    </tr>
                </thead>
                <tbody>
EOF

    # Ajouter les données dans le tableau HTML
    while IFS=',' read -r elapsed connections bandwidth orchestrator active_conn processes rx_bytes tx_bytes; do
        if [[ "$elapsed" =~ ^[0-9]+$ ]]; then
            local orch_class="status-ok"
            if [[ "$orchestrator" == "timeout" ]]; then
                orch_class="status-error"
            elif [[ "$orchestrator" == "disabled" ]]; then
                orch_class="status-warning"
            fi
            
            echo "                    <tr>" >> "$report_file"
            echo "                        <td>$elapsed</td>" >> "$report_file"
            echo "                        <td>$connections</td>" >> "$report_file"
            echo "                        <td>$bandwidth</td>" >> "$report_file"
            echo "                        <td><span class=\"$orch_class\">$orchestrator</span></td>" >> "$report_file"
            echo "                        <td>$active_conn</td>" >> "$report_file"
            echo "                        <td>$processes</td>" >> "$report_file"
            echo "                        <td>$(format_bytes "$rx_bytes")</td>" >> "$report_file"
            echo "                        <td>$(format_bytes "$tx_bytes")</td>" >> "$report_file"
            echo "                    </tr>" >> "$report_file"
        fi
    done < <(grep -v '^#' "$TEMP_DATA_FILE" | grep -v '^$')

    cat >> "$report_file" << EOF
                </tbody>
            </table>
        </div>
        
        <div class="footer">
            <p>Généré par MeshWatch v$MESHWATCH_VERSION - Star Déception Mesh Monitoring</p>
            <p>$(date)</p>
        </div>
    </div>
</body>
</html>
EOF

    printf "\033[0;32m✅ Rapport HTML généré: %s\033[0m\n" "$report_file"
    
    # Afficher un résumé
    echo ""
    echo -e "\033[1;37m=== Résumé du Rapport ===\033[0m"
    echo "$data_analysis" | head -20
}

analyze_collected_data() {
    if [[ ! -f "$TEMP_DATA_FILE" ]]; then
        echo "Aucune donnée collectée"
        return
    fi
    
    local data_lines=$(grep -v '^#' "$TEMP_DATA_FILE" | grep -v '^$' | wc -l)
    if (( data_lines == 0 )); then
        echo "Aucune donnée valide collectée"
        return
    fi
    
    # Calculer les statistiques
    local total_samples=$data_lines
    local avg_connections=$(awk -F',' 'NR>1 && !/^#/ && NF>=2 {sum+=$2; count++} END {if(count>0) print int(sum/count); else print 0}' "$TEMP_DATA_FILE")
    local max_connections=$(awk -F',' 'NR>1 && !/^#/ && NF>=2 {if($2>max) max=$2} END {print max+0}' "$TEMP_DATA_FILE")
    local avg_bandwidth=$(awk -F',' 'NR>1 && !/^#/ && NF>=3 {sum+=$3; count++} END {if(count>0) print int(sum/count); else print 0}' "$TEMP_DATA_FILE")
    local max_bandwidth=$(awk -F',' 'NR>1 && !/^#/ && NF>=3 {if($3>max) max=$3} END {print max+0}' "$TEMP_DATA_FILE")
    
    # Compter les timeouts orchestrateur
    local orchestrator_timeouts=$(awk -F',' 'NR>1 && !/^#/ && $4=="timeout" {count++} END {print count+0}' "$TEMP_DATA_FILE")
    local orchestrator_ok=$(awk -F',' 'NR>1 && !/^#/ && $4=="ok" {count++} END {print count+0}' "$TEMP_DATA_FILE")
    
    # Calculer la durée totale
    local first_timestamp=$(awk -F',' 'NR>1 && !/^#/ && NF>=1 {print $1; exit}' "$TEMP_DATA_FILE")
    local last_timestamp=$(awk -F',' 'NR>1 && !/^#/ && NF>=1 {timestamp=$1} END {print timestamp}' "$TEMP_DATA_FILE")
    local duration=$((last_timestamp - first_timestamp))
    
    cat << EOF
Statistiques de la Surveillance:
  Durée totale: ${duration}s
  Échantillons collectés: $total_samples
  Intervalle d'échantillonnage: ~$((duration / total_samples))s

Connexions Mesh:
  Moyenne: $avg_connections connexions
  Maximum: $max_connections connexions
  Seuil configuré: $(get_config MAX_CONN) connexions

Débit Réseau:
  Moyenne: ${avg_bandwidth} Mbps
  Maximum: ${max_bandwidth} Mbps
  Seuil configuré: $(get_config MAX_BANDWIDTH_MBPS) Mbps

Orchestrateur Star Déception:
  Connexions réussies: $orchestrator_ok
  Timeouts: $orchestrator_timeouts
  Taux de succès: $(( orchestrator_ok * 100 / (orchestrator_ok + orchestrator_timeouts) ))%

Recommandations:
$(generate_recommendations "$avg_connections" "$max_connections" "$avg_bandwidth" "$max_bandwidth" "$orchestrator_timeouts" "$total_samples")
EOF
}

generate_recommendations() {
    local avg_conn="$1"
    local max_conn="$2"
    local avg_bandwidth="$3"
    local max_bandwidth="$4"
    local timeouts="$5"
    local samples="$6"
    
    local recommendations=""
    local max_conn_threshold=$(get_config MAX_CONN)
    local max_bandwidth_threshold=$(get_config MAX_BANDWIDTH_MBPS)
    
    # Recommandations sur les connexions
    if (( max_conn > max_conn_threshold )); then
        recommendations+="  ⚠️  Pic de connexions dépassant le seuil ($max_conn > $max_conn_threshold)\n"
        recommendations+="      → Considérer l'augmentation du seuil ou l'optimisation mesh\n"
    elif (( avg_conn > max_conn_threshold * 80 / 100 )); then
        recommendations+="  ⚠️  Connexions moyennes élevées (${avg_conn} > 80% du seuil)\n"
        recommendations+="      → Surveiller l'évolution de la charge mesh\n"
    else
        recommendations+="  ✅ Niveau de connexions mesh normal\n"
    fi
    
    # Recommandations sur le débit
    if (( max_bandwidth > max_bandwidth_threshold )); then
        recommendations+="  ⚠️  Pic de débit dépassant le seuil ($max_bandwidth > $max_bandwidth_threshold Mbps)\n"
        recommendations+="      → Vérifier la synchronisation inter-serveurs\n"
    elif (( avg_bandwidth > max_bandwidth_threshold * 70 / 100 )); then
        recommendations+="  ⚠️  Débit moyen élevé (${avg_bandwidth} > 70% du seuil)\n"
        recommendations+="      → Optimiser les flux de données mesh\n"
    else
        recommendations+="  ✅ Débit mesh dans les limites normales\n"
    fi
    
    # Recommandations sur l'orchestrateur
    local timeout_rate=$((timeouts * 100 / samples))
    if (( timeout_rate > 10 )); then
        recommendations+="  🔴 Taux de timeout orchestrateur élevé (${timeout_rate}%)\n"
        recommendations+="      → Vérifier la connectivité réseau et la charge orchestrateur\n"
    elif (( timeout_rate > 5 )); then
        recommendations+="  ⚠️  Timeouts orchestrateur occasionnels (${timeout_rate}%)\n"
        recommendations+="      → Surveiller la stabilité de la connexion\n"
    else
        recommendations+="  ✅ Connexion orchestrateur stable\n"
    fi
    
    echo -e "$recommendations"
}

format_bytes() {
    local bytes="$1"
    if (( bytes > 1073741824 )); then
        echo "$((bytes / 1073741824)) GB"
    elif (( bytes > 1048576 )); then
        echo "$((bytes / 1048576)) MB"
    elif (( bytes > 1024 )); then
        echo "$((bytes / 1024)) KB"
    else
        echo "$bytes B"
    fi
}

configure_temporary_monitoring() {
    echo -e "${YELLOW}=== Configuration Surveillance Temporaire ===${NC}"
    echo ""
    echo -e "${BLUE}Durée de surveillance (en secondes):${NC}"
    echo -e "${CYAN}Exemples: 300 (5min), 600 (10min), 1800 (30min), 3600 (1h)${NC}"
    read -r duration
    
    if ! [[ "$duration" =~ ^[0-9]+$ ]] || (( duration < 30 )); then
        echo -e "${RED}Durée invalide (minimum 30 secondes)${NC}"
        return 1
    fi
    
    echo ""
    echo -e "${BLUE}Format du rapport:${NC}"
    echo "1) TXT (texte simple)"
    echo "2) HTML (rapport web interactif)"
    read -r format_choice
    
    local format="txt"
    case $format_choice in
        1) format="txt" ;;
        2) format="html" ;;
        *) format="txt" ;;
    esac
    
    echo ""
    echo -e "${GREEN}Configuration:${NC}"
    echo -e "  Durée: ${duration}s ($((duration / 60))min $((duration % 60))s)"
    echo -e "  Format: $format"
    echo ""
    echo -n "Démarrer la surveillance ? (o/N): "
    read -r confirm
    
    if [[ "$confirm" =~ ^[oO]$ ]]; then
        start_temporary_monitoring "$duration" "$format"
    else
        echo -e "${YELLOW}Surveillance annulée${NC}"
    fi
}

list_reports() {
    echo -e "${PURPLE}=== Rapports MeshWatch Disponibles ===${NC}"
    echo ""
    
    if [[ ! -d "$REPORTS_DIR" ]] || [[ -z "$(ls -A "$REPORTS_DIR" 2>/dev/null)" ]]; then
        echo -e "${YELLOW}Aucun rapport disponible${NC}"
        echo -e "${CYAN}Utilisez l'option 'Surveillance temporaire' pour générer des rapports${NC}"
        return
    fi
    
    local count=0
    for report in "$REPORTS_DIR"/meshwatch_report_*.{txt,html}; do
        if [[ -f "$report" ]]; then
            ((count++))
            local filename=$(basename "$report")
            local size=$(du -h "$report" | cut -f1)
            local date=$(stat -c %y "$report" | cut -d' ' -f1,2 | cut -d'.' -f1)
            
            echo -e "${WHITE}$count) $filename${NC}"
            echo -e "   Taille: $size | Date: $date"
            echo ""
        fi
    done
    
    if (( count == 0 )); then
        echo -e "${YELLOW}Aucun rapport trouvé${NC}"
    else
        echo -e "${CYAN}Répertoire des rapports: $REPORTS_DIR${NC}"
    fi
}