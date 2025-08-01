@@ .. @@
     # Charger les valeurs par défaut pour les clés manquantes
     for key in "${!DEFAULT_CONFIG[@]}"; do
         if [[ -z "${CONFIG[$key]:-}" ]]; then
             CONFIG["$key"]="${DEFAULT_CONFIG[$key]}"
         fi
     done
-        # Ignorer les commentaires et lignes vides
-        [[ "$key" =~ ^[[:space:]]*# ]] && continue
-        [[ -z "$key" ]] && continue
-        
-        # Nettoyer les guillemets
-        value=$(echo "$value" | sed 's/^"//;s/"$//')
-        CONFIG["$key"]="$value"
-    done < "$DEFAULT_CONFIG_FILE"
-    
-    # Surcharger avec la configuration utilisateur
-    if [[ -f "$CONFIG_FILE" ]]; then
-        while IFS='=' read -r key value; do
-            [[ "$key" =~ ^[[:space:]]*# ]] && continue
-            [[ -z "$key" ]] && continue
-            
-            value=$(echo "$value" | sed 's/^"//;s/"$//')
-            CONFIG["$key"]="$value"
-        done < "$CONFIG_FILE"
-    fi
     
     # Auto-détecter l'interface si nécessaire
     if [[ -z "${CONFIG[INTERFACE]}" ]]; then