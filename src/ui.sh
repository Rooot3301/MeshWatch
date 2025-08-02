@@ .. @@
     echo "7)  $(get_message "menu_show_config")"
     echo "8)  $(get_message "menu_change_lang")"
     echo "9)  $(get_message "menu_advanced")"
-    echo "10) Mettre à jour MeshWatch"
-    echo "11) Informations version"
-    echo "12) $(get_message "menu_quit")"
+    echo "10) Surveillance temporaire + rapport"
+    echo "11) Voir rapports disponibles"
+    echo "12) Mettre à jour MeshWatch"
+    echo "13) Informations version"
+    echo "14) $(get_message "menu_quit")"
     echo ""
     echo -n "Choix: "
 }
@@ .. @@
             9)
                 advanced_config_menu
                 ;;
             10)
+                configure_temporary_monitoring
+                read -p "$(get_message "press_enter")" -r
+                ;;
+            11)
+                list_reports
+                read -p "$(get_message "press_enter")" -r
+                ;;
+            12)
                 update_meshwatch
                 read -p "$(get_message "press_enter")" -r
                 ;;
-            11)
+            13)
                 show_version_info
                 read -p "$(get_message "press_enter")" -r
                 ;;
-            12)
+            14)
                 echo -e "${GREEN}Au revoir!${NC}"
                 exit 0
                 ;;
             *)
                 echo -e "${RED}$(get_message "invalid_choice")${NC}"
-                read -p "$(get_message "press_enter")" -r
+                read -p "$(get_message "press_enter")" -r
                 ;;
         esac
         
-        if [[ $choice != 8 ]]; then
        if [[ $choice != 14 ]]; then
+        if [[ $choice != 14 ]]; then
             read -p "$(get_message "press_enter")" -r
         fi
     done