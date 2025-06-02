#!/bin/bash

echo "=== Ataque a /etc/passwd ==="

# Verifica que el script parametrizado exista
if [ ! -f "./script_1_attack_params.sh" ]; then
    echo "[ERROR] No se encontró script_1_attack_params.sh"
    exit 1
fi

# Ejecutar ataque a /etc/passwd
echo
echo "[+] Ejecutando ataque a /etc/passwd..."
./script_1_attack_params.sh -p

echo
echo "[✓] Ataque Finalizado"
