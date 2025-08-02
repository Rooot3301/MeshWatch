@@ .. @@
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
+    --temp-monitor DURATION FORMAT  Surveillance temporaire (ex: --temp-monitor 300 html)
 
 EXEMPLES:
     ./meshwatch.sh              # Interface interactive mesh
     ./meshwatch.sh --status     # Statut surveillance mesh
     ./meshwatch.sh --config     # Configuration Star Déception
+    ./meshwatch.sh --temp-monitor 600 txt  # Surveillance 10min + rapport TXT
 
 FICHIERS:
     Configuration: $CONFIG_DIR/meshwatch.conf
     Logs: $LOGS_DIR/meshwatch.log
+    Rapports: $SCRIPT_DIR/reports/
     PID: /tmp/meshwatch.pid
 
 STAR DÉCEPTION:
     Ports mesh par défaut: 7777,7778,7779
     Orchestrateur: orchestrator.star-deception.com
     Discord: #mesh-monitoring
 
 Pour plus d'informations: README.md
 EOF
 }
@@ .. @@
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
+            --temp-monitor)
+                if [[ $# -lt 3 ]]; then
+                    echo "Usage: --temp-monitor DURATION FORMAT" >&2
+                    echo "Exemple: --temp-monitor 300 html" >&2
+                    exit 1
+                fi
+                shift
+                local duration="$1"
+                shift
+                local format="$1"
+                
+                if ! [[ "$duration" =~ ^[0-9]+$ ]] || (( duration < 30 )); then
+                    echo "Erreur: Durée invalide (minimum 30 secondes)" >&2
+                    exit 1
+                fi
+                
+                if [[ "$format" != "txt" && "$format" != "html" ]]; then
+                    echo "Erreur: Format invalide (txt ou html)" >&2
+                    exit 1
+                fi
+                
+                load_config
+                start_temporary_monitoring "$duration" "$format"
+                exit 0
+                ;;
             *)
                 echo "Option inconnue: $1" >&2
                 show_help
                 exit 1
                 ;;
         esac
         shift
     done
 }
@@ .. @@
 main() {
+    # Traiter les arguments de ligne de commande
+    parse_arguments "$@"
+    
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